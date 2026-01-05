using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StickBy.Api.Services;
using StickBy.Shared.Models.WebSession;

namespace StickBy.Api.Controllers;

/// <summary>
/// Handles web session pairing (like WhatsApp Web).
/// Website generates QR code, mobile app scans and authorizes.
/// </summary>
[ApiController]
[Route("api/web-session")]
public class WebSessionController : ControllerBase
{
    private readonly IWebSessionService _webSessionService;

    public WebSessionController(IWebSessionService webSessionService)
    {
        _webSessionService = webSessionService;
    }

    /// <summary>
    /// Create a new web session pairing request.
    /// Called by website to get a token for QR code display.
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<WebSessionCreateResponse>> CreateSession()
    {
        var result = await _webSessionService.CreateSessionAsync(
            Request.Headers.UserAgent,
            GetIpAddress());

        return Ok(result);
    }

    /// <summary>
    /// Get the status of a web session.
    /// Called by website to poll for authorization.
    /// </summary>
    [HttpGet("{pairingToken}/status")]
    public async Task<ActionResult<WebSessionStatusResponse>> GetSessionStatus(string pairingToken)
    {
        var result = await _webSessionService.GetSessionStatusAsync(pairingToken);
        return Ok(result);
    }

    /// <summary>
    /// Authorize a web session.
    /// Called by mobile app after scanning QR code.
    /// </summary>
    [Authorize]
    [HttpPost("authorize")]
    public async Task<IActionResult> AuthorizeSession([FromBody] WebSessionAuthorizeRequest request)
    {
        var userId = GetUserId();
        if (userId == null)
            return Unauthorized();

        var success = await _webSessionService.AuthorizeSessionAsync(
            userId.Value,
            request.PairingToken,
            GetIpAddress());

        if (!success)
            return BadRequest(new { message = "Invalid or expired pairing token" });

        return Ok(new { message = "Web session authorized successfully" });
    }

    /// <summary>
    /// Get all active web sessions for the current user.
    /// </summary>
    [Authorize]
    [HttpGet]
    public async Task<ActionResult<List<WebSessionDto>>> GetActiveSessions()
    {
        var userId = GetUserId();
        if (userId == null)
            return Unauthorized();

        var sessions = await _webSessionService.GetActiveSessionsAsync(userId.Value);
        return Ok(sessions);
    }

    /// <summary>
    /// Invalidate a specific web session.
    /// </summary>
    [Authorize]
    [HttpDelete("{sessionId}")]
    public async Task<IActionResult> InvalidateSession(Guid sessionId)
    {
        var userId = GetUserId();
        if (userId == null)
            return Unauthorized();

        var success = await _webSessionService.InvalidateSessionAsync(userId.Value, sessionId);
        if (!success)
            return NotFound(new { message = "Session not found" });

        return Ok(new { message = "Session invalidated successfully" });
    }

    /// <summary>
    /// Invalidate all web sessions for the current user.
    /// </summary>
    [Authorize]
    [HttpDelete]
    public async Task<IActionResult> InvalidateAllSessions()
    {
        var userId = GetUserId();
        if (userId == null)
            return Unauthorized();

        await _webSessionService.InvalidateAllSessionsAsync(userId.Value);
        return Ok(new { message = "All sessions invalidated successfully" });
    }

    private Guid? GetUserId()
    {
        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
            return null;
        return userId;
    }

    private string? GetIpAddress()
    {
        if (Request.Headers.TryGetValue("X-Forwarded-For", out var header))
            return header.FirstOrDefault();

        return HttpContext.Connection.RemoteIpAddress?.ToString();
    }
}
