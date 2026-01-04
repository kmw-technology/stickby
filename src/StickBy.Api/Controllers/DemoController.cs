using Microsoft.AspNetCore.Mvc;
using StickBy.Api.Services;

namespace StickBy.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DemoController : ControllerBase
{
    private readonly IDemoSessionService _sessionService;
    private readonly ILogger<DemoController> _logger;

    public DemoController(IDemoSessionService sessionService, ILogger<DemoController> logger)
    {
        _sessionService = sessionService;
        _logger = logger;
    }

    /// <summary>
    /// Generate a new unique session code for demo sync
    /// </summary>
    [HttpPost("session/create")]
    public async Task<IActionResult> CreateSession([FromBody] CreateSessionRequest request)
    {
        var sessionCode = await _sessionService.GenerateSessionCodeAsync();
        var session = await _sessionService.GetOrCreateSessionAsync(sessionCode, request.SyncMode);

        _logger.LogInformation("Created new demo session {SessionCode} in {Mode} mode", sessionCode, request.SyncMode);

        return Ok(new CreateSessionResponse
        {
            SessionCode = sessionCode,
            SyncMode = session.SyncMode,
            CreatedAt = session.CreatedAt
        });
    }

    /// <summary>
    /// Check if a session exists and get its info
    /// </summary>
    [HttpGet("session/{sessionCode}")]
    public async Task<IActionResult> GetSession(string sessionCode)
    {
        var session = await _sessionService.GetSessionAsync(sessionCode);

        if (session == null)
        {
            return NotFound(new { error = "SESSION_NOT_FOUND", message = "Session does not exist" });
        }

        return Ok(new SessionInfoResponse
        {
            SessionCode = session.SessionCode,
            SyncMode = session.SyncMode,
            ParticipantCount = session.Participants.Count,
            Participants = session.Participants.Select(p => new ParticipantInfo
            {
                IdentityId = p.IdentityId,
                JoinedAt = p.JoinedAt
            }).ToList(),
            CurrentEpoch = session.CurrentEpoch,
            CreatedAt = session.CreatedAt,
            LastActivityAt = session.LastActivityAt
        });
    }

    /// <summary>
    /// Get list of available demo identities
    /// </summary>
    [HttpGet("identities")]
    public IActionResult GetIdentities()
    {
        var identities = new List<DemoIdentity>
        {
            new() { Id = "nicolas-wild", Name = "Nicolas Wild", Email = "nicolas.wild@googlemail.com", AvatarPath = "nw.jpg", Color = "#2563eb" },
            new() { Id = "clara-nguyen", Name = "Clara Nguyen", Email = "clara.nguyen@web.de", AvatarPath = "cn.jpg", Color = "#dc2626" },
            new() { Id = "andreas-bauer", Name = "Andreas Bauer", Email = "andreas.bauer@gmail.com", AvatarPath = "ab.jpg", Color = "#16a34a" },
            new() { Id = "andrea-wimmer", Name = "Andrea Wimmer", Email = "andrea.wimmer@example.com", AvatarPath = "aw.jpg", Color = "#9333ea" },
            new() { Id = "anna-dannhauser", Name = "Anna Dannhauser", Email = "anna.dannhauser@example.com", AvatarPath = "ad.jpg", Color = "#ea580c" },
            new() { Id = "stefan-keller", Name = "Stefan Keller", Email = "stefan.keller@example.com", AvatarPath = "sk.jpg", Color = "#0891b2" },
            new() { Id = "tobias-bauer", Name = "Tobias Bauer", Email = "tobias.bauer@example.com", AvatarPath = "tb.jpg", Color = "#4f46e5" },
            new() { Id = "jana-belawa", Name = "Jana Belawa", Email = "jana.belawa@example.com", AvatarPath = "jb.jpg", Color = "#be185d" },
            new() { Id = "leonie-austin", Name = "Leonie Austin", Email = "leonie.austin@example.com", AvatarPath = "la.jpg", Color = "#059669" }
        };

        return Ok(identities);
    }
}

// Request/Response DTOs
public record CreateSessionRequest
{
    public string SyncMode { get; init; } = "p2p"; // "p2p" or "database"
}

public record CreateSessionResponse
{
    public required string SessionCode { get; init; }
    public required string SyncMode { get; init; }
    public DateTime CreatedAt { get; init; }
}

public record SessionInfoResponse
{
    public required string SessionCode { get; init; }
    public required string SyncMode { get; init; }
    public int ParticipantCount { get; init; }
    public List<ParticipantInfo> Participants { get; init; } = new();
    public long CurrentEpoch { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime LastActivityAt { get; init; }
}

public record ParticipantInfo
{
    public required string IdentityId { get; init; }
    public DateTime JoinedAt { get; init; }
}

public record DemoIdentity
{
    public required string Id { get; init; }
    public required string Name { get; init; }
    public required string Email { get; init; }
    public required string AvatarPath { get; init; }
    public required string Color { get; init; }
}
