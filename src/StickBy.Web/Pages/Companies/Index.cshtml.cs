using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StickBy.Shared.Models.Companies;
using StickBy.Web.Services;

namespace StickBy.Web.Pages.Companies;

[Authorize]
public class IndexModel : PageModel
{
    private readonly IApiService _apiService;

    public IndexModel(IApiService apiService)
    {
        _apiService = apiService;
    }

    public List<CompanyDto> Companies { get; set; } = new();

    [BindProperty(SupportsGet = true)]
    public bool ShowContractors { get; set; }

    public async Task OnGetAsync(bool? contractors)
    {
        ShowContractors = contractors ?? false;
        var all = await _apiService.GetCompaniesAsync();
        Companies = all.Where(c => c.IsContractor == ShowContractors).ToList();
    }
}
