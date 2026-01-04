using Microsoft.AspNetCore.SignalR;
using StickBy.Api.Services;

namespace StickBy.Api.Hubs;

/// <summary>
/// SignalR Hub for multi-device demo synchronization.
/// Supports two modes:
/// 1. P2P Mode: Server relays encrypted messages (sees nothing, privacy-first)
/// 2. Database Mode: Server stores encrypted data and broadcasts updates
/// </summary>
public class DemoSyncHub : Hub
{
    private readonly IDemoSessionService _sessionService;
    private readonly ILogger<DemoSyncHub> _logger;

    public DemoSyncHub(IDemoSessionService sessionService, ILogger<DemoSyncHub> logger)
    {
        _sessionService = sessionService;
        _logger = logger;
    }

    /// <summary>
    /// Join a demo session with a specific identity
    /// </summary>
    /// <param name="sessionCode">6-character session code</param>
    /// <param name="identityId">The demo identity (e.g., "nicolas-wild", "clara-nguyen")</param>
    /// <param name="publicKey">Client's public key for P2P encryption (Base64)</param>
    /// <param name="syncMode">Sync mode: "p2p" or "database"</param>
    public async Task JoinSession(string sessionCode, string identityId, string publicKey, string syncMode)
    {
        var session = await _sessionService.GetOrCreateSessionAsync(sessionCode, syncMode);

        // Check if identity is already taken in this session
        if (session.Participants.Any(p => p.IdentityId == identityId && p.ConnectionId != Context.ConnectionId))
        {
            await Clients.Caller.SendAsync("Error", "IDENTITY_TAKEN", $"Identity '{identityId}' is already in use in this session");
            return;
        }

        // Add participant to session
        var participant = new DemoParticipant
        {
            ConnectionId = Context.ConnectionId,
            IdentityId = identityId,
            PublicKey = publicKey,
            JoinedAt = DateTime.UtcNow
        };

        await _sessionService.AddParticipantAsync(sessionCode, participant);
        await Groups.AddToGroupAsync(Context.ConnectionId, sessionCode);

        _logger.LogInformation("Client {ConnectionId} joined session {SessionCode} as {IdentityId}",
            Context.ConnectionId, sessionCode, identityId);

        // Notify all participants about the new member
        var otherParticipants = session.Participants
            .Where(p => p.ConnectionId != Context.ConnectionId)
            .Select(p => new { p.IdentityId, p.PublicKey })
            .ToList();

        await Clients.Caller.SendAsync("SessionJoined", new
        {
            SessionCode = sessionCode,
            SyncMode = session.SyncMode,
            Participants = otherParticipants,
            CurrentState = session.SyncMode == "database" ? session.EncryptedState : null
        });

        await Clients.OthersInGroup(sessionCode).SendAsync("ParticipantJoined", new
        {
            IdentityId = identityId,
            PublicKey = publicKey
        });
    }

    /// <summary>
    /// Leave the current demo session
    /// </summary>
    public async Task LeaveSession()
    {
        var session = await _sessionService.GetSessionByConnectionAsync(Context.ConnectionId);
        if (session == null) return;

        var participant = session.Participants.FirstOrDefault(p => p.ConnectionId == Context.ConnectionId);
        if (participant == null) return;

        await _sessionService.RemoveParticipantAsync(session.SessionCode, Context.ConnectionId);
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, session.SessionCode);

        _logger.LogInformation("Client {ConnectionId} left session {SessionCode}",
            Context.ConnectionId, session.SessionCode);

        await Clients.OthersInGroup(session.SessionCode).SendAsync("ParticipantLeft", new
        {
            IdentityId = participant.IdentityId
        });
    }

    /// <summary>
    /// P2P Mode: Relay an encrypted message to all other participants
    /// Server cannot read the content - only forwards the encrypted payload
    /// </summary>
    /// <param name="encryptedPayload">Base64 encoded encrypted message</param>
    /// <param name="targetIdentityId">Optional: specific recipient identity (null = broadcast)</param>
    public async Task RelayP2PMessage(string encryptedPayload, string? targetIdentityId = null)
    {
        var session = await _sessionService.GetSessionByConnectionAsync(Context.ConnectionId);
        if (session == null)
        {
            await Clients.Caller.SendAsync("Error", "NOT_IN_SESSION", "You are not in a session");
            return;
        }

        if (session.SyncMode != "p2p")
        {
            await Clients.Caller.SendAsync("Error", "WRONG_MODE", "P2P relay only available in P2P mode");
            return;
        }

        var sender = session.Participants.FirstOrDefault(p => p.ConnectionId == Context.ConnectionId);
        if (sender == null) return;

        var message = new
        {
            SenderIdentityId = sender.IdentityId,
            EncryptedPayload = encryptedPayload,
            Timestamp = DateTime.UtcNow
        };

        if (!string.IsNullOrEmpty(targetIdentityId))
        {
            // Send to specific participant
            var target = session.Participants.FirstOrDefault(p => p.IdentityId == targetIdentityId);
            if (target != null)
            {
                await Clients.Client(target.ConnectionId).SendAsync("P2PMessage", message);
            }
        }
        else
        {
            // Broadcast to all others in session
            await Clients.OthersInGroup(session.SessionCode).SendAsync("P2PMessage", message);
        }
    }

    /// <summary>
    /// Database Mode: Submit an encrypted state update
    /// Server stores the encrypted state and broadcasts to all participants
    /// </summary>
    /// <param name="encryptedState">Base64 encoded encrypted state</param>
    /// <param name="epoch">Version number for conflict resolution</param>
    public async Task SubmitDatabaseUpdate(string encryptedState, long epoch)
    {
        var session = await _sessionService.GetSessionByConnectionAsync(Context.ConnectionId);
        if (session == null)
        {
            await Clients.Caller.SendAsync("Error", "NOT_IN_SESSION", "You are not in a session");
            return;
        }

        if (session.SyncMode != "database")
        {
            await Clients.Caller.SendAsync("Error", "WRONG_MODE", "Database updates only available in database mode");
            return;
        }

        // Check epoch for conflict resolution
        if (epoch <= session.CurrentEpoch)
        {
            await Clients.Caller.SendAsync("Error", "EPOCH_CONFLICT", "Your epoch is outdated. Please refresh and retry.");
            return;
        }

        var sender = session.Participants.FirstOrDefault(p => p.ConnectionId == Context.ConnectionId);
        if (sender == null) return;

        // Update session state
        await _sessionService.UpdateSessionStateAsync(session.SessionCode, encryptedState, epoch);

        _logger.LogInformation("Session {SessionCode} state updated to epoch {Epoch} by {IdentityId}",
            session.SessionCode, epoch, sender.IdentityId);

        // Broadcast to all participants (including sender for confirmation)
        await Clients.Group(session.SessionCode).SendAsync("StateUpdated", new
        {
            SenderIdentityId = sender.IdentityId,
            EncryptedState = encryptedState,
            Epoch = epoch,
            Timestamp = DateTime.UtcNow
        });
    }

    /// <summary>
    /// Request current state from the session (Database mode only)
    /// </summary>
    public async Task RequestCurrentState()
    {
        var session = await _sessionService.GetSessionByConnectionAsync(Context.ConnectionId);
        if (session == null)
        {
            await Clients.Caller.SendAsync("Error", "NOT_IN_SESSION", "You are not in a session");
            return;
        }

        if (session.SyncMode != "database")
        {
            await Clients.Caller.SendAsync("Error", "WRONG_MODE", "State request only available in database mode");
            return;
        }

        await Clients.Caller.SendAsync("CurrentState", new
        {
            EncryptedState = session.EncryptedState,
            Epoch = session.CurrentEpoch,
            Timestamp = DateTime.UtcNow
        });
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        await LeaveSession();
        await base.OnDisconnectedAsync(exception);
    }
}

/// <summary>
/// Represents a participant in a demo session
/// </summary>
public class DemoParticipant
{
    public required string ConnectionId { get; set; }
    public required string IdentityId { get; set; }
    public required string PublicKey { get; set; }
    public DateTime JoinedAt { get; set; }
}

/// <summary>
/// Represents a demo sync session
/// </summary>
public class DemoSession
{
    public required string SessionCode { get; set; }
    public required string SyncMode { get; set; } // "p2p" or "database"
    public List<DemoParticipant> Participants { get; set; } = new();
    public string? EncryptedState { get; set; } // For database mode
    public long CurrentEpoch { get; set; } // Version number for conflict resolution
    public DateTime CreatedAt { get; set; }
    public DateTime LastActivityAt { get; set; }
}
