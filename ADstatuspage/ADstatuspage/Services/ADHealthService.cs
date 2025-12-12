using ADstatuspage.Data;
using ADstatuspage.Models;
using Microsoft.Extensions.Caching.Memory;
using System.Diagnostics;
using System.DirectoryServices;
using System.DirectoryServices.ActiveDirectory;
using System.Management.Automation;
using System.Net.NetworkInformation;
using System.Net.Sockets;

namespace ADstatuspage.Services;

public class ADHealthService : IADHealthService
{
    private readonly IMemoryCache _cache;
    private readonly ApplicationDbContext _context;
    private readonly ILogger<ADHealthService> _logger;
    private const int CacheExpirationSeconds = 60;

    public ADHealthService(IMemoryCache cache, ApplicationDbContext context, ILogger<ADHealthService> logger)
    {
        _cache = cache;
        _context = context;
        _logger = logger;
    }

    public async Task<List<DomainControllerInfo>> GetDomainControllers()
    {
        return await _cache.GetOrCreateAsync("DomainControllers", async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(CacheExpirationSeconds);
            var stopwatch = Stopwatch.StartNew();
            
            try
            {
                var dcs = new List<DomainControllerInfo>();
                
                // Get domain controllers using DirectoryServices
                try
                {
                    var domain = Domain.GetCurrentDomain();
                    foreach (DomainController dc in domain.DomainControllers)
                    {
                        var dcInfo = new DomainControllerInfo
                        {
                            Name = dc.Name,
                            Site = dc.SiteName ?? "Unknown",
                            OperatingSystem = dc.OSVersion ?? "Unknown"
                        };

                        // Test connectivity
                        dcInfo.IsPingable = await PingHost(dc.Name);
                        dcInfo.IsLdapReachable = await TestPort(dc.Name, 389);
                        dcInfo.IsLdapsReachable = await TestPort(dc.Name, 636);
                        
                        dcInfo.Status = (dcInfo.IsPingable && dcInfo.IsLdapReachable) ? "Up" : 
                                       dcInfo.IsPingable ? "Degraded" : "Down";
                        
                        dcs.Add(dcInfo);
                        dc.Dispose();
                    }
                    domain.Dispose();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error retrieving domain controllers using DirectoryServices");
                    
                    // Fallback: try PowerShell
                    dcs = await GetDomainControllersViaPowerShell();
                }

                stopwatch.Stop();
                await LogHealthCheck("DomainControllers", dcs.Any(d => d.Status == "Down") ? "Down" : 
                    dcs.Any(d => d.Status == "Degraded") ? "Degraded" : "Up", 
                    (int)stopwatch.ElapsedMilliseconds, null);

                return dcs;
            }
            catch (Exception ex)
            {
                stopwatch.Stop();
                _logger.LogError(ex, "Error getting domain controllers");
                await LogHealthCheck("DomainControllers", "Error", (int)stopwatch.ElapsedMilliseconds, ex.Message);
                return new List<DomainControllerInfo>();
            }
        }) ?? new List<DomainControllerInfo>();
    }

    private async Task<List<DomainControllerInfo>> GetDomainControllersViaPowerShell()
    {
        var dcs = new List<DomainControllerInfo>();
        
        try
        {
            using var ps = PowerShell.Create();
            ps.AddScript(@"
                try {
                    Get-ADDomainController -Filter * | Select-Object Name, Site, OperatingSystem
                } catch {
                    # Fallback if AD module not available
                    [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().DomainControllers | 
                    Select-Object @{N='Name';E={$_.Name}}, @{N='Site';E={$_.SiteName}}, @{N='OperatingSystem';E={$_.OSVersion}}
                }
            ");

            var results = await Task.Run(() => ps.Invoke());
            
            foreach (var result in results)
            {
                var name = result.Properties["Name"]?.Value?.ToString() ?? "Unknown";
                var dcInfo = new DomainControllerInfo
                {
                    Name = name,
                    Site = result.Properties["Site"]?.Value?.ToString() ?? "Unknown",
                    OperatingSystem = result.Properties["OperatingSystem"]?.Value?.ToString() ?? "Unknown",
                    IsPingable = await PingHost(name),
                    IsLdapReachable = await TestPort(name, 389),
                    IsLdapsReachable = await TestPort(name, 636)
                };
                
                dcInfo.Status = (dcInfo.IsPingable && dcInfo.IsLdapReachable) ? "Up" : 
                               dcInfo.IsPingable ? "Degraded" : "Down";
                
                dcs.Add(dcInfo);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting domain controllers via PowerShell");
        }

        return dcs;
    }

    public async Task<ReplicationSummary> GetReplicationSummary()
    {
        return await _cache.GetOrCreateAsync("ReplicationSummary", async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(CacheExpirationSeconds);
            var stopwatch = Stopwatch.StartNew();
            
            try
            {
                var summary = new ReplicationSummary();
                
                using var ps = PowerShell.Create();
                ps.AddScript("repadmin /replsummary");
                
                var timeoutTask = Task.Delay(TimeSpan.FromSeconds(30));
                var invokeTask = Task.Run(() => ps.Invoke());
                var completedTask = await Task.WhenAny(invokeTask, timeoutTask);
                
                if (completedTask == timeoutTask)
                {
                    ps.Stop();
                    throw new TimeoutException("Repadmin command timed out");
                }
                
                var results = await invokeTask;
                
                // Parse repadmin output
                foreach (var line in results)
                {
                    var lineText = line.ToString();
                    
                    if (lineText.Contains("fail", StringComparison.OrdinalIgnoreCase))
                    {
                        summary.FailureCount++;
                        summary.RecentFailures.Add(lineText.Trim());
                    }
                    
                    // Parse latency information (example pattern, adjust as needed)
                    if (lineText.Contains("seconds", StringComparison.OrdinalIgnoreCase))
                    {
                        var parts = lineText.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
                        foreach (var part in parts)
                        {
                            if (double.TryParse(part, out double latency))
                            {
                                summary.MaxLatencySeconds = Math.Max(summary.MaxLatencySeconds, latency);
                                summary.AvgLatencySeconds = (summary.AvgLatencySeconds + latency) / 2;
                            }
                        }
                    }
                }
                
                summary.Status = summary.FailureCount > 0 ? "Degraded" : "Up";

                stopwatch.Stop();
                await LogHealthCheck("Replication", summary.Status, (int)stopwatch.ElapsedMilliseconds, null);
                
                return summary;
            }
            catch (Exception ex)
            {
                stopwatch.Stop();
                _logger.LogError(ex, "Error getting replication summary");
                await LogHealthCheck("Replication", "Error", (int)stopwatch.ElapsedMilliseconds, ex.Message);
                return new ReplicationSummary { Status = "Error" };
            }
        }) ?? new ReplicationSummary { Status = "Error" };
    }

    public async Task<DnsHealthInfo> GetDnsHealth()
    {
        return await _cache.GetOrCreateAsync("DnsHealth", async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(CacheExpirationSeconds);
            var stopwatch = Stopwatch.StartNew();
            
            try
            {
                var dnsInfo = new DnsHealthInfo();
                
                // Test DNS resolution
                var testQueries = new Dictionary<string, string>
                {
                    { "A", "_ldap._tcp.dc._msdcs." + GetDomainName() },
                    { "SRV", "_ldap._tcp.dc._msdcs." + GetDomainName() }
                };

                foreach (var query in testQueries)
                {
                    var testResult = new DnsTestResult
                    {
                        RecordType = query.Key,
                        Query = query.Value
                    };

                    try
                    {
                        using var ps = PowerShell.Create();
                        ps.AddScript($"Resolve-DnsName -Name '{query.Value}' -Type {query.Key} -ErrorAction Stop");
                        
                        var timeoutTask = Task.Delay(TimeSpan.FromSeconds(10));
                        var invokeTask = Task.Run(() => ps.Invoke());
                        var completedTask = await Task.WhenAny(invokeTask, timeoutTask);
                        
                        if (completedTask == timeoutTask)
                        {
                            ps.Stop();
                            testResult.Successful = false;
                            testResult.ErrorMessage = "Timeout";
                        }
                        else
                        {
                            var results = await invokeTask;
                            testResult.Successful = results.Any() && !ps.HadErrors;
                            if (ps.HadErrors)
                            {
                                testResult.ErrorMessage = string.Join(", ", ps.Streams.Error.Select(e => e.ToString()));
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        testResult.Successful = false;
                        testResult.ErrorMessage = ex.Message;
                    }

                    dnsInfo.TestResults.Add(testResult);
                }

                // Assume forwarders are healthy if basic DNS works
                dnsInfo.ForwardersHealthy = dnsInfo.TestResults.Any(t => t.Successful);
                dnsInfo.Status = dnsInfo.TestResults.All(t => t.Successful) ? "Up" : 
                                dnsInfo.TestResults.Any(t => t.Successful) ? "Degraded" : "Down";

                stopwatch.Stop();
                await LogHealthCheck("DNS", dnsInfo.Status, (int)stopwatch.ElapsedMilliseconds, null);
                
                return dnsInfo;
            }
            catch (Exception ex)
            {
                stopwatch.Stop();
                _logger.LogError(ex, "Error getting DNS health");
                await LogHealthCheck("DNS", "Error", (int)stopwatch.ElapsedMilliseconds, ex.Message);
                return new DnsHealthInfo { Status = "Error" };
            }
        }) ?? new DnsHealthInfo { Status = "Error" };
    }

    public async Task<List<ServiceStatusInfo>> GetAdServicesStatus()
    {
        return await _cache.GetOrCreateAsync("AdServicesStatus", async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(CacheExpirationSeconds);
            var stopwatch = Stopwatch.StartNew();
            
            try
            {
                var serviceStatusList = new List<ServiceStatusInfo>();
                var dcs = await GetDomainControllers();

                var criticalServices = new[] { "NTDS", "DNS", "DFSR" };

                foreach (var dc in dcs.Take(5)) // Limit to first 5 DCs to avoid timeout
                {
                    var statusInfo = new ServiceStatusInfo
                    {
                        DomainController = dc.Name
                    };

                    try
                    {
                        using var ps = PowerShell.Create();
                        ps.AddScript($@"
                            Get-Service -ComputerName '{dc.Name}' -Name NTDS,DNS,DFSR -ErrorAction SilentlyContinue | 
                            Select-Object Name, DisplayName, Status
                        ");

                        var timeoutTask = Task.Delay(TimeSpan.FromSeconds(15));
                        var invokeTask = Task.Run(() => ps.Invoke());
                        var completedTask = await Task.WhenAny(invokeTask, timeoutTask);
                        
                        if (completedTask == timeoutTask)
                        {
                            ps.Stop();
                            statusInfo.OverallStatus = "Timeout";
                        }
                        else
                        {
                            var results = await invokeTask;
                            
                            foreach (var result in results)
                            {
                                statusInfo.Services.Add(new ServiceStatus
                                {
                                    ServiceName = result.Properties["Name"]?.Value?.ToString() ?? "Unknown",
                                    DisplayName = result.Properties["DisplayName"]?.Value?.ToString() ?? "Unknown",
                                    Status = result.Properties["Status"]?.Value?.ToString() ?? "Unknown"
                                });
                            }

                            statusInfo.OverallStatus = statusInfo.Services.All(s => s.IsRunning) ? "Up" :
                                                      statusInfo.Services.Any(s => s.IsRunning) ? "Degraded" : "Down";
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, $"Error getting services for {dc.Name}");
                        statusInfo.OverallStatus = "Error";
                    }

                    serviceStatusList.Add(statusInfo);
                }

                stopwatch.Stop();
                var overallStatus = serviceStatusList.All(s => s.OverallStatus == "Up") ? "Up" :
                                   serviceStatusList.Any(s => s.OverallStatus == "Up" || s.OverallStatus == "Degraded") ? "Degraded" : "Down";
                await LogHealthCheck("Services", overallStatus, (int)stopwatch.ElapsedMilliseconds, null);
                
                return serviceStatusList;
            }
            catch (Exception ex)
            {
                stopwatch.Stop();
                _logger.LogError(ex, "Error getting AD services status");
                await LogHealthCheck("Services", "Error", (int)stopwatch.ElapsedMilliseconds, ex.Message);
                return new List<ServiceStatusInfo>();
            }
        }) ?? new List<ServiceStatusInfo>();
    }

    public async Task<OverallHealth> GetOverallHealth()
    {
        var dcs = await GetDomainControllers();
        var replication = await GetReplicationSummary();
        var dns = await GetDnsHealth();
        var services = await GetAdServicesStatus();

        var overall = new OverallHealth
        {
            Timestamp = DateTime.Now,
            DomainControllersStatus = dcs.Any(d => d.Status == "Down") ? "Down" : 
                                     dcs.Any(d => d.Status == "Degraded") ? "Degraded" : "Up",
            ReplicationStatus = replication.Status,
            DnsStatus = dns.Status,
            ServicesStatus = services.All(s => s.OverallStatus == "Up") ? "Up" :
                           services.Any(s => s.OverallStatus == "Up" || s.OverallStatus == "Degraded") ? "Degraded" : "Down"
        };

        var statuses = new[] { overall.DomainControllersStatus, overall.ReplicationStatus, 
                              overall.DnsStatus, overall.ServicesStatus };
        
        overall.Status = statuses.Any(s => s == "Down" || s == "Error") ? "Down" :
                        statuses.Any(s => s == "Degraded") ? "Degraded" : "Up";

        return overall;
    }

    private async Task<bool> PingHost(string hostname)
    {
        try
        {
            using var ping = new Ping();
            var reply = await ping.SendPingAsync(hostname, 2000);
            return reply.Status == IPStatus.Success;
        }
        catch
        {
            return false;
        }
    }

    private async Task<bool> TestPort(string hostname, int port)
    {
        try
        {
            using var client = new TcpClient();
            var connectTask = client.ConnectAsync(hostname, port);
            var timeoutTask = Task.Delay(3000);
            var completedTask = await Task.WhenAny(connectTask, timeoutTask);
            
            return completedTask == connectTask && client.Connected;
        }
        catch
        {
            return false;
        }
    }

    private string GetDomainName()
    {
        try
        {
            var domain = Domain.GetCurrentDomain();
            var name = domain.Name;
            domain.Dispose();
            return name;
        }
        catch
        {
            return "domain.local";
        }
    }

    private async Task LogHealthCheck(string section, string status, int durationMs, string? message)
    {
        try
        {
            var log = new HealthCheckLog
            {
                Section = section,
                Status = status,
                DurationMs = durationMs,
                Timestamp = DateTime.Now,
                OptionalMessage = message
            };

            _context.HealthCheckLogs.Add(log);
            await _context.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error logging health check");
        }
    }
}
