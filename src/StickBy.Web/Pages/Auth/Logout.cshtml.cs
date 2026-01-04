using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StickBy.Web.Services;

namespace StickBy.Web.Pages.Auth;

public class LogoutModel : PageModel
{
    private readonly IApiService _apiService;

    public LogoutModel(IApiService apiService)
    {
        _apiService = apiService;
    }

    public async Task<IActionResult> OnPostAsync()
    {
        _apiService.ClearAccessToken();
        await HttpContext.SignOutAsync("Cookies");
        return RedirectToPage("/Index");
    }
}
