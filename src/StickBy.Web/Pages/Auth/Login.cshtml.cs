using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StickBy.Shared.Models.Auth;
using StickBy.Shared.Models.WebSession;
using StickBy.Web.Services;

namespace StickBy.Web.Pages.Auth;

public class LoginModel : PageModel
{
    private readonly IApiService _apiService;

    public LoginModel(IApiService apiService)
    {
        _apiService = apiService;
    }

    public string? PairingToken { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public string? ErrorMessage { get; set; }

    public async Task<IActionResult> OnGetAsync()
    {
        // Create a new web session for QR pairing
        var session = await _apiService.CreateWebSessionAsync();
        if (session == null)
        {
            ErrorMessage = "Verbindung zum Server fehlgeschlagen.";
            return Page();
        }

        PairingToken = session.PairingToken;
        ExpiresAt = session.ExpiresAt;

        return Page();
    }

    /// <summary>
    /// Called when the JavaScript detects that the session has been authorized.
    /// Completes the sign-in process.
    /// </summary>
    public async Task<IActionResult> OnPostCompleteAsync([FromForm] string token)
    {
        if (string.IsNullOrEmpty(token))
        {
            ErrorMessage = "Ungültiger Token.";
            return Page();
        }

        // Get the session status to retrieve auth tokens
        var status = await _apiService.GetWebSessionStatusAsync(token);
        if (status == null || status.Status != WebSessionStatus.Authorized || status.Auth == null)
        {
            ErrorMessage = "Sitzung nicht autorisiert.";
            return Page();
        }

        // Store the API token
        _apiService.SetAccessToken(status.Auth.AccessToken);

        // Create authentication cookie
        var claims = new List<Claim>
        {
            new(ClaimTypes.Email, status.Auth.User?.Email ?? ""),
            new(ClaimTypes.Name, status.Auth.User?.DisplayName ?? "User"),
            new(ClaimTypes.NameIdentifier, status.Auth.User?.Id.ToString() ?? "")
        };

        var identity = new ClaimsIdentity(claims, "Cookies");
        var principal = new ClaimsPrincipal(identity);

        await HttpContext.SignInAsync("Cookies", principal);

        return RedirectToPage("/Home");
    }

    /// <summary>
    /// API endpoint for JavaScript to poll session status.
    /// </summary>
    public async Task<IActionResult> OnGetStatusAsync([FromQuery] string token)
    {
        if (string.IsNullOrEmpty(token))
        {
            return new JsonResult(new { status = "error" });
        }

        var status = await _apiService.GetWebSessionStatusAsync(token);
        if (status == null)
        {
            return new JsonResult(new { status = "error" });
        }

        return new JsonResult(new { status = status.Status.ToString().ToLower() });
    }
}
