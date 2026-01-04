using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StickBy.Web.Services;

namespace StickBy.Web.Pages.Onboarding;

[Authorize]
public class WelcomeModel : PageModel
{
    private readonly IApiService _apiService;

    public WelcomeModel(IApiService apiService)
    {
        _apiService = apiService;
    }

    public string DisplayName { get; set; } = string.Empty;

    public async Task OnGetAsync()
    {
        var profile = await _apiService.GetProfileAsync();
        if (profile != null)
        {
            DisplayName = profile.DisplayName;
        }
    }

    public IActionResult OnPost()
    {
        return RedirectToPage("./Details");
    }
}
