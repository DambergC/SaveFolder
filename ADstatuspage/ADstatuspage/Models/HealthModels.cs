namespace ADstatuspage.Models;

public class DomainControllerInfo
{
    public string Name { get; set; } = string.Empty;
    public string Site { get; set; } = string.Empty;
    public string OperatingSystem { get; set; } = string.Empty;
    public bool IsPingable { get; set; }
    public bool IsLdapReachable { get; set; }
    public bool IsLdapsReachable { get; set; }
    public string Status { get; set; } = "Unknown";
}

public class ReplicationSummary
{
    public int TotalPartners { get; set; }
    public int FailureCount { get; set; }
    public double MaxLatencySeconds { get; set; }
    public double AvgLatencySeconds { get; set; }
    public List<string> RecentFailures { get; set; } = new();
    public string Status { get; set; } = "Unknown";
}

public class DnsHealthInfo
{
    public List<DnsTestResult> TestResults { get; set; } = new();
    public bool ForwardersHealthy { get; set; }
    public string Status { get; set; } = "Unknown";
}

public class DnsTestResult
{
    public string RecordType { get; set; } = string.Empty;
    public string Query { get; set; } = string.Empty;
    public bool Successful { get; set; }
    public string? ErrorMessage { get; set; }
}

public class ServiceStatusInfo
{
    public string DomainController { get; set; } = string.Empty;
    public List<ServiceStatus> Services { get; set; } = new();
    public string OverallStatus { get; set; } = "Unknown";
}

public class ServiceStatus
{
    public string ServiceName { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public bool IsRunning => Status.Equals("Running", StringComparison.OrdinalIgnoreCase);
}

public class OverallHealth
{
    public string Status { get; set; } = "Unknown";
    public DateTime Timestamp { get; set; }
    public string DomainControllersStatus { get; set; } = "Unknown";
    public string ReplicationStatus { get; set; } = "Unknown";
    public string DnsStatus { get; set; } = "Unknown";
    public string ServicesStatus { get; set; } = "Unknown";
}
