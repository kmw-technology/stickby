using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StickBy.Shared.Models.Companies;
using StickBy.Web.Services;

namespace StickBy.Web.Pages.Companies;

[Authorize]
public class DetailsModel : PageModel
{
    private readonly IApiService _apiService;

    public DetailsModel(IApiService apiService)
    {
        _apiService = apiService;
    }

    public CompanyDto? Company { get; set; }

    public async Task<IActionResult> OnGetAsync(Guid id)
    {
        Company = await _apiService.GetCompanyAsync(id);
        if (Company == null)
        {
            return NotFound();
        }
        return Page();
    }
}
