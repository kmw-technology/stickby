using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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

    [BindProperty]
    public string? ImageUrl { get; set; }

    public string? SuccessMessage { get; set; }

    public async Task OnGetAsync()
    {
        Profile = await _apiService.GetProfileAsync();
    }

    public async Task<IActionResult> OnPostUpdateImageAsync()
    {
        if (!string.IsNullOrWhiteSpace(ImageUrl))
        {
            var success = await _apiService.UpdateProfileImageAsync(ImageUrl);
            if (success)
            {
                SuccessMessage = "Profilbild wurde aktualisiert!";
            }
        }

        Profile = await _apiService.GetProfileAsync();
        return Page();
    }
}
