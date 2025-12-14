using ADstatuspage.Models;
using ADstatuspage.Services;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace ADstatuspage.Pages;

public class ServicesModel : PageModel
{
    private readonly IADHealthService _healthService;
    private readonly ILogger<ServicesModel> _logger;

    public ServicesModel(IADHealthService healthService, ILogger<ServicesModel> logger)
    {
        _healthService = healthService;
        _logger = logger;
    }

    public List<ServiceStatusInfo> ServicesStatus { get; set; } = new();

    public async Task OnGetAsync()
    {
        try
        {
            ServicesStatus = await _healthService.GetAdServicesStatus();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading services status");
        }
    }
}
