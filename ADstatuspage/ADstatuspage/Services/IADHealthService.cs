using ADstatuspage.Models;

namespace ADstatuspage.Services;

public interface IADHealthService
{
    Task<List<DomainControllerInfo>> GetDomainControllers();
    Task<ReplicationSummary> GetReplicationSummary();
    Task<DnsHealthInfo> GetDnsHealth();
    Task<List<ServiceStatusInfo>> GetAdServicesStatus();
    Task<OverallHealth> GetOverallHealth();
}
