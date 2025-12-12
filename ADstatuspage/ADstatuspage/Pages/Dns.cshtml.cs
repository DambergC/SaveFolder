using ADstatuspage.Models;
using ADstatuspage.Services;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace ADstatuspage.Pages;

public class DnsModel : PageModel
{
    private readonly IADHealthService _healthService;
    private readonly ILogger<DnsModel> _logger;

    public DnsModel(IADHealthService healthService, ILogger<DnsModel> logger)
    {
        _healthService = healthService;
        _logger = logger;
    }

    public DnsHealthInfo DnsHealth { get; set; } = new();

    public async Task OnGetAsync()
    {
        try
        {
            DnsHealth = await _healthService.GetDnsHealth();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading DNS health");
        }
    }
}
