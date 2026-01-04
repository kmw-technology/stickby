using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StickBy.Shared.Models.Auth;
using StickBy.Web.Services;

namespace StickBy.Web.Pages.Auth;

public class RegisterModel : PageModel
{
    private readonly IApiService _apiService;

    public RegisterModel(IApiService apiService)
    {
        _apiService = apiService;
    }

    [BindProperty]
    public string DisplayName { get; set; } = string.Empty;

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
        if (string.IsNullOrEmpty(DisplayName) || string.IsNullOrEmpty(Email) || string.IsNullOrEmpty(Password))
        {
            ErrorMessage = "Bitte alle Felder ausfüllen.";
            return Page();
        }

        var result = await _apiService.RegisterAsync(new RegisterRequest
        {
            DisplayName = DisplayName,
            Email = Email,
            Password = Password
        });

        if (result == null)
        {
            ErrorMessage = "Registrierung fehlgeschlagen. E-Mail möglicherweise bereits vergeben.";
            return Page();
        }

        // Store the API token
        _apiService.SetAccessToken(result.AccessToken);

        // Create authentication cookie
        var claims = new List<Claim>
        {
            new(ClaimTypes.Email, Email),
            new(ClaimTypes.Name, DisplayName)
        };

        var identity = new ClaimsIdentity(claims, "Cookies");
        var principal = new ClaimsPrincipal(identity);

        await HttpContext.SignInAsync("Cookies", principal);

        return RedirectToPage("/Onboarding/Welcome");
    }
}
