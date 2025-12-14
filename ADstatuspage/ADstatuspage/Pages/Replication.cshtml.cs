using ADstatuspage.Models;
using ADstatuspage.Services;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace ADstatuspage.Pages;

public class ReplicationModel : PageModel
{
    private readonly IADHealthService _healthService;
    private readonly ILogger<ReplicationModel> _logger;

    public ReplicationModel(IADHealthService healthService, ILogger<ReplicationModel> logger)
    {
        _healthService = healthService;
        _logger = logger;
    }

    public ReplicationSummary ReplicationSummary { get; set; } = new();

    public async Task OnGetAsync()
    {
        try
        {
            ReplicationSummary = await _healthService.GetReplicationSummary();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading replication summary");
        }
    }
}
