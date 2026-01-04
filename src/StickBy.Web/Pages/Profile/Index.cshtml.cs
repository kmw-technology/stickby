using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StickBy.Shared.Models.Profile;
using StickBy.Web.Services;

namespace StickBy.Web.Pages.Profile;

[Authorize]
public class IndexModel : PageModel
{
    private readonly IApiService _apiService;

    public IndexModel(IApiService apiService)
    {
        _apiService = apiService;
    }

    public ProfileDto? Profile { get; set; }

    public async Task OnGetAsync()
    {
        Profile = await _apiService.GetProfileAsync();
    }
}
