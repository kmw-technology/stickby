using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StickBy.Api.Services;
using StickBy.Shared.Models.Auth;

namespace StickBy.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("register")]
    public async Task<ActionResult<AuthResponse>> Register([FromBody] RegisterRequest request)
    {
        var result = await _authService.RegisterAsync(request, GetIpAddress());
        if (result == null)
            return BadRequest(new { message = "Email already registered" });

        return Ok(result);
    }

    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request)
    {
        var result = await _authService.LoginAsync(request, GetIpAddress());
        if (result == null)
            return Unauthorized(new { message = "Invalid credentials" });

        return Ok(result);
    }

    [HttpPost("magic-link/request")]
    public async Task<IActionResult> RequestMagicLink([FromBody] MagicLinkRequest request)
    {
        var token = await _authService.RequestMagicLinkAsync(request);

        // Always return success to prevent email enumeration
        // In production, send email here
        if (token != null)
        {
            // TODO: Send email with magic link
            // For development, log the token
            Console.WriteLine($"Magic Link Token: {token}");
        }

        return Ok(new { message = "If the email exists, a magic link has been sent" });
    }

    [HttpPost("magic-link/verify")]
    public async Task<ActionResult<AuthResponse>> VerifyMagicLink([FromBody] MagicLinkVerifyRequest request)
    {
        var result = await _authService.VerifyMagicLinkAsync(request, GetIpAddress());
        if (result == null)
            return BadRequest(new { message = "Invalid or expired magic link" });

        return Ok(result);
    }

    [HttpPost("refresh")]
    public async Task<ActionResult<AuthResponse>> RefreshToken([FromBody] RefreshTokenRequest request)
    {
        var result = await _authService.RefreshTokenAsync(request.RefreshToken, GetIpAddress());
        if (result == null)
            return Unauthorized(new { message = "Invalid refresh token" });

        return Ok(result);
    }

    [Authorize]
    [HttpPost("logout")]
    public async Task<IActionResult> Logout([FromBody] RefreshTokenRequest request)
    {
        await _authService.RevokeTokenAsync(request.RefreshToken, GetIpAddress());
        return Ok(new { message = "Logged out successfully" });
    }

    private string? GetIpAddress()
    {
        if (Request.Headers.TryGetValue("X-Forwarded-For", out var header))
            return header.FirstOrDefault();

        return HttpContext.Connection.RemoteIpAddress?.ToString();
    }
}
