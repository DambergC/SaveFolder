using ADstatuspage.Models;
using ADstatuspage.Services;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace ADstatuspage.Pages;

public class IndexModel : PageModel
{
    private readonly IADHealthService _healthService;
    private readonly ILogger<IndexModel> _logger;

    public IndexModel(IADHealthService healthService, ILogger<IndexModel> logger)
    {
        _healthService = healthService;
        _logger = logger;
    }

    public OverallHealth? OverallHealth { get; set; }

    public async Task OnGetAsync()
    {
        try
        {
            OverallHealth = await _healthService.GetOverallHealth();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading overall health");
            OverallHealth = new OverallHealth
            {
                Status = "Error",
                Timestamp = DateTime.Now,
                DomainControllersStatus = "Error",
                ReplicationStatus = "Error",
                DnsStatus = "Error",
                ServicesStatus = "Error"
            };
        }
    }
}
