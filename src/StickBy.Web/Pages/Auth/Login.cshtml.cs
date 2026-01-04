using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StickBy.Shared.Models.Auth;
using StickBy.Web.Services;

namespace StickBy.Web.Pages.Auth;

public class LoginModel : PageModel
{
    private readonly IApiService _apiService;

    public LoginModel(IApiService apiService)
    {
        _apiService = apiService;
    }

    [BindProperty]
    public string Email { get; set; } = string.Empty;

    [BindProperty]
    public string Password { get; set; } = string.Empty;

    public string? ErrorMessage { get; set; }

    public void OnGet()
    {
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (string.IsNullOrEmpty(Email) || string.IsNullOrEmpty(Password))
        {
            ErrorMessage = "Bitte E-Mail und Passwort eingeben.";
            return Page();
        }

        var result = await _apiService.LoginAsync(new LoginRequest
        {
            Email = Email,
            Password = Password
        });

        if (result == null)
        {
            ErrorMessage = "Ungültige Anmeldedaten.";
            return Page();
        }

        // Store the API token
        _apiService.SetAccessToken(result.AccessToken);

        // Create authentication cookie
        var claims = new List<Claim>
        {
            new(ClaimTypes.Email, Email),
            new(ClaimTypes.Name, result.User?.DisplayName ?? Email)
        };

        var identity = new ClaimsIdentity(claims, "Cookies");
        var principal = new ClaimsPrincipal(identity);

        await HttpContext.SignInAsync("Cookies", principal);

        return RedirectToPage("/Home");
    }
}
