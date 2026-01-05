using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using StickBy.Infrastructure.Data;
using StickBy.Infrastructure.Entities;
using StickBy.Shared.Models.Auth;
using StickBy.Shared.Models.WebSession;

namespace StickBy.Api.Services;

public interface IWebSessionService
{
    /// <summary>
    /// Create a new web session pairing request (called by website).
    /// </summary>
    Task<WebSessionCreateResponse> CreateSessionAsync(string? userAgent, string? ipAddress);

    /// <summary>
    /// Get the status of a web session (called by website to poll for authorization).
    /// </summary>
    Task<WebSessionStatusResponse> GetSessionStatusAsync(string pairingToken);

    /// <summary>
    /// Authorize a web session (called by mobile app after scanning QR).
    /// </summary>
    Task<bool> AuthorizeSessionAsync(Guid userId, string pairingToken, string? ipAddress);

    /// <summary>
    /// Get all active web sessions for a user.
    /// </summary>
    Task<List<WebSessionDto>> GetActiveSessionsAsync(Guid userId);

    /// <summary>
    /// Invalidate a specific web session.
    /// </summary>
    Task<bool> InvalidateSessionAsync(Guid userId, Guid sessionId);

    /// <summary>
    /// Invalidate all web sessions for a user.
    /// </summary>
    Task InvalidateAllSessionsAsync(Guid userId);

    /// <summary>
    /// Update last activity timestamp for a session.
    /// </summary>
    Task UpdateActivityAsync(string accessToken);
}

public class WebSessionService : IWebSessionService
{
    private readonly StickByDbContext _context;
    private readonly IJwtService _jwtService;
    private readonly IConfiguration _configuration;

    // Configuration constants
    private const int PairingTokenExpiryMinutes = 5;
    private const int SessionExpiryDays = 30;

    public WebSessionService(
        StickByDbContext context,
        IJwtService jwtService,
        IConfiguration configuration)
    {
        _context = context;
        _jwtService = jwtService;
        _configuration = configuration;
    }

    public async Task<WebSessionCreateResponse> CreateSessionAsync(string? userAgent, string? ipAddress)
    {
        var pairingToken = GenerateSecureToken();
        var expiresAt = DateTime.UtcNow.AddMinutes(PairingTokenExpiryMinutes);

        var session = new WebSession
        {
            PairingToken = pairingToken,
            PairingExpiresAt = expiresAt,
            UserAgent = userAgent,
            IpAddress = ipAddress,
            DeviceName = ParseDeviceName(userAgent)
        };

        _context.WebSessions.Add(session);
        await _context.SaveChangesAsync();

        return new WebSessionCreateResponse
        {
            SessionId = session.Id,
            PairingToken = pairingToken,
            ExpiresAt = expiresAt
        };
    }

    public async Task<WebSessionStatusResponse> GetSessionStatusAsync(string pairingToken)
    {
        var session = await _context.WebSessions
            .Include(ws => ws.User)
            .FirstOrDefaultAsync(ws => ws.PairingToken == pairingToken);

        if (session == null)
        {
            return new WebSessionStatusResponse { Status = WebSessionStatus.NotFound };
        }

        if (session.IsInvalidated)
        {
            return new WebSessionStatusResponse { Status = WebSessionStatus.Invalidated };
        }

        if (session.IsAuthorized)
        {
            // Session is authorized, return the tokens
            return new WebSessionStatusResponse
            {
                Status = WebSessionStatus.Authorized,
                Auth = new AuthResponse
                {
                    AccessToken = session.AccessToken!,
                    RefreshToken = session.RefreshToken!,
                    ExpiresAt = DateTime.UtcNow.AddMinutes(
                        int.Parse(_configuration["Jwt:ExpiryMinutes"] ?? "15")),
                    User = new UserDto
                    {
                        Id = session.User!.Id,
                        Email = session.User.Email ?? string.Empty,
                        DisplayName = session.User.DisplayName
                    }
                }
            };
        }

        if (session.IsPairingExpired)
        {
            return new WebSessionStatusResponse { Status = WebSessionStatus.Expired };
        }

        return new WebSessionStatusResponse { Status = WebSessionStatus.Pending };
    }

    public async Task<bool> AuthorizeSessionAsync(Guid userId, string pairingToken, string? ipAddress)
    {
        var session = await _context.WebSessions
            .FirstOrDefaultAsync(ws => ws.PairingToken == pairingToken);

        if (session == null || session.IsPairingExpired || session.IsAuthorized)
        {
            return false;
        }

        var user = await _context.Users.FindAsync(userId);
        if (user == null || !user.IsActive)
        {
            return false;
        }

        // Generate tokens for the web session
        var accessToken = _jwtService.GenerateAccessToken(user);
        var refreshToken = _jwtService.GenerateRefreshToken();

        // Store refresh token
        var refreshTokenEntity = new RefreshToken
        {
            UserId = userId,
            Token = refreshToken,
            ExpiresAt = DateTime.UtcNow.AddDays(
                int.Parse(_configuration["Jwt:RefreshTokenExpiryDays"] ?? "7")),
            CreatedByIp = ipAddress
        };
        _context.RefreshTokens.Add(refreshTokenEntity);

        // Update session
        session.UserId = userId;
        session.AccessToken = accessToken;
        session.RefreshToken = refreshToken;
        session.AuthorizedAt = DateTime.UtcNow;
        session.SessionExpiresAt = DateTime.UtcNow.AddDays(SessionExpiryDays);
        session.LastActivityAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<List<WebSessionDto>> GetActiveSessionsAsync(Guid userId)
    {
        var sessions = await _context.WebSessions
            .Where(ws => ws.UserId == userId && ws.AuthorizedAt != null && ws.InvalidatedAt == null)
            .OrderByDescending(ws => ws.LastActivityAt ?? ws.AuthorizedAt)
            .ToListAsync();

        return sessions
            .Where(s => s.IsActive)
            .Select(s => new WebSessionDto
            {
                Id = s.Id,
                DeviceName = s.DeviceName,
                UserAgent = s.UserAgent,
                IpAddress = s.IpAddress,
                AuthorizedAt = s.AuthorizedAt!.Value,
                LastActivityAt = s.LastActivityAt,
                IsActive = s.IsActive
            })
            .ToList();
    }

    public async Task<bool> InvalidateSessionAsync(Guid userId, Guid sessionId)
    {
        var session = await _context.WebSessions
            .FirstOrDefaultAsync(ws => ws.Id == sessionId && ws.UserId == userId);

        if (session == null)
        {
            return false;
        }

        session.InvalidatedAt = DateTime.UtcNow;

        // Also revoke the refresh token
        if (!string.IsNullOrEmpty(session.RefreshToken))
        {
            var refreshToken = await _context.RefreshTokens
                .FirstOrDefaultAsync(rt => rt.Token == session.RefreshToken);
            if (refreshToken != null)
            {
                refreshToken.RevokedAt = DateTime.UtcNow;
            }
        }

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task InvalidateAllSessionsAsync(Guid userId)
    {
        var sessions = await _context.WebSessions
            .Where(ws => ws.UserId == userId && ws.InvalidatedAt == null)
            .ToListAsync();

        var refreshTokens = sessions
            .Where(s => !string.IsNullOrEmpty(s.RefreshToken))
            .Select(s => s.RefreshToken!)
            .ToList();

        foreach (var session in sessions)
        {
            session.InvalidatedAt = DateTime.UtcNow;
        }

        // Revoke all associated refresh tokens
        var tokensToRevoke = await _context.RefreshTokens
            .Where(rt => refreshTokens.Contains(rt.Token) && rt.RevokedAt == null)
            .ToListAsync();

        foreach (var token in tokensToRevoke)
        {
            token.RevokedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
    }

    public async Task UpdateActivityAsync(string accessToken)
    {
        var session = await _context.WebSessions
            .FirstOrDefaultAsync(ws => ws.AccessToken == accessToken && ws.InvalidatedAt == null);

        if (session != null)
        {
            session.LastActivityAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }
    }

    private static string GenerateSecureToken()
    {
        var bytes = new byte[32];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(bytes);
        return Convert.ToBase64String(bytes)
            .Replace("+", "-")
            .Replace("/", "_")
            .TrimEnd('=');
    }

    private static string? ParseDeviceName(string? userAgent)
    {
        if (string.IsNullOrEmpty(userAgent))
            return null;

        // Simple parsing for common browsers/platforms
        if (userAgent.Contains("Chrome") && !userAgent.Contains("Edg"))
            return userAgent.Contains("Windows") ? "Chrome on Windows" :
                   userAgent.Contains("Mac") ? "Chrome on Mac" :
                   userAgent.Contains("Linux") ? "Chrome on Linux" : "Chrome";

        if (userAgent.Contains("Firefox"))
            return userAgent.Contains("Windows") ? "Firefox on Windows" :
                   userAgent.Contains("Mac") ? "Firefox on Mac" :
                   userAgent.Contains("Linux") ? "Firefox on Linux" : "Firefox";

        if (userAgent.Contains("Safari") && !userAgent.Contains("Chrome"))
            return "Safari on Mac";

        if (userAgent.Contains("Edg"))
            return userAgent.Contains("Windows") ? "Edge on Windows" :
                   userAgent.Contains("Mac") ? "Edge on Mac" : "Edge";

        return "Web Browser";
    }
}
