using ADstatuspage.Models;
using ADstatuspage.Services;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace ADstatuspage.Pages;

public class DomainControllersModel : PageModel
{
    private readonly IADHealthService _healthService;
    private readonly ILogger<DomainControllersModel> _logger;

    public DomainControllersModel(IADHealthService healthService, ILogger<DomainControllersModel> logger)
    {
        _healthService = healthService;
        _logger = logger;
    }

    public List<DomainControllerInfo> DomainControllers { get; set; } = new();

    public async Task OnGetAsync()
    {
        try
        {
            DomainControllers = await _healthService.GetDomainControllers();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading domain controllers");
        }
    }
}
