using System.Collections.Concurrent;
using StickBy.Api.Hubs;

namespace StickBy.Api.Services;

public interface IDemoSessionService
{
    Task<DemoSession> GetOrCreateSessionAsync(string sessionCode, string syncMode);
    Task<DemoSession?> GetSessionAsync(string sessionCode);
    Task<DemoSession?> GetSessionByConnectionAsync(string connectionId);
    Task AddParticipantAsync(string sessionCode, DemoParticipant participant);
    Task RemoveParticipantAsync(string sessionCode, string connectionId);
    Task UpdateSessionStateAsync(string sessionCode, string encryptedState, long epoch);
    Task<string> GenerateSessionCodeAsync();
    Task CleanupExpiredSessionsAsync();
}

/// <summary>
/// In-memory service for managing demo sync sessions.
/// Sessions are temporary and don't persist across server restarts.
/// </summary>
public class DemoSessionService : IDemoSessionService
{
    private readonly ConcurrentDictionary<string, DemoSession> _sessions = new();
    private readonly ConcurrentDictionary<string, string> _connectionToSession = new();
    private readonly ILogger<DemoSessionService> _logger;
    private readonly TimeSpan _sessionTimeout = TimeSpan.FromHours(4);
    private static readonly Random _random = new();

    public DemoSessionService(ILogger<DemoSessionService> logger)
    {
        _logger = logger;
    }

    public Task<DemoSession> GetOrCreateSessionAsync(string sessionCode, string syncMode)
    {
        var normalizedCode = sessionCode.ToUpperInvariant();

        var session = _sessions.GetOrAdd(normalizedCode, code => new DemoSession
        {
            SessionCode = code,
            SyncMode = syncMode.ToLowerInvariant(),
            Participants = new List<DemoParticipant>(),
            CreatedAt = DateTime.UtcNow,
            LastActivityAt = DateTime.UtcNow,
            CurrentEpoch = 0
        });

        session.LastActivityAt = DateTime.UtcNow;
        return Task.FromResult(session);
    }

    public Task<DemoSession?> GetSessionAsync(string sessionCode)
    {
        var normalizedCode = sessionCode.ToUpperInvariant();
        _sessions.TryGetValue(normalizedCode, out var session);
        return Task.FromResult(session);
    }

    public Task<DemoSession?> GetSessionByConnectionAsync(string connectionId)
    {
        if (_connectionToSession.TryGetValue(connectionId, out var sessionCode))
        {
            _sessions.TryGetValue(sessionCode, out var session);
            return Task.FromResult(session);
        }
        return Task.FromResult<DemoSession?>(null);
    }

    public Task AddParticipantAsync(string sessionCode, DemoParticipant participant)
    {
        var normalizedCode = sessionCode.ToUpperInvariant();

        if (_sessions.TryGetValue(normalizedCode, out var session))
        {
            lock (session.Participants)
            {
                // Remove any existing entry for this connection
                session.Participants.RemoveAll(p => p.ConnectionId == participant.ConnectionId);
                session.Participants.Add(participant);
            }

            _connectionToSession[participant.ConnectionId] = normalizedCode;
            session.LastActivityAt = DateTime.UtcNow;

            _logger.LogDebug("Added participant {IdentityId} to session {SessionCode}. Total: {Count}",
                participant.IdentityId, normalizedCode, session.Participants.Count);
        }

        return Task.CompletedTask;
    }

    public Task RemoveParticipantAsync(string sessionCode, string connectionId)
    {
        var normalizedCode = sessionCode.ToUpperInvariant();

        if (_sessions.TryGetValue(normalizedCode, out var session))
        {
            lock (session.Participants)
            {
                session.Participants.RemoveAll(p => p.ConnectionId == connectionId);
            }

            _connectionToSession.TryRemove(connectionId, out _);
            session.LastActivityAt = DateTime.UtcNow;

            // Remove session if empty
            if (session.Participants.Count == 0)
            {
                _sessions.TryRemove(normalizedCode, out _);
                _logger.LogInformation("Session {SessionCode} removed (no participants)", normalizedCode);
            }
        }

        return Task.CompletedTask;
    }

    public Task UpdateSessionStateAsync(string sessionCode, string encryptedState, long epoch)
    {
        var normalizedCode = sessionCode.ToUpperInvariant();

        if (_sessions.TryGetValue(normalizedCode, out var session))
        {
            session.EncryptedState = encryptedState;
            session.CurrentEpoch = epoch;
            session.LastActivityAt = DateTime.UtcNow;
        }

        return Task.CompletedTask;
    }

    public Task<string> GenerateSessionCodeAsync()
    {
        const string chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // No I, O, 0, 1 to avoid confusion
        string code;

        do
        {
            code = new string(Enumerable.Range(0, 6)
                .Select(_ => chars[_random.Next(chars.Length)])
                .ToArray());
        } while (_sessions.ContainsKey(code));

        return Task.FromResult(code);
    }

    public Task CleanupExpiredSessionsAsync()
    {
        var expiredSessions = _sessions
            .Where(kvp => DateTime.UtcNow - kvp.Value.LastActivityAt > _sessionTimeout)
            .Select(kvp => kvp.Key)
            .ToList();

        foreach (var sessionCode in expiredSessions)
        {
            if (_sessions.TryRemove(sessionCode, out var session))
            {
                foreach (var participant in session.Participants)
                {
                    _connectionToSession.TryRemove(participant.ConnectionId, out _);
                }
                _logger.LogInformation("Cleaned up expired session {SessionCode}", sessionCode);
            }
        }

        return Task.CompletedTask;
    }
}

/// <summary>
/// Background service to periodically cleanup expired demo sessions
/// </summary>
public class DemoSessionCleanupService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<DemoSessionCleanupService> _logger;
    private readonly TimeSpan _cleanupInterval = TimeSpan.FromMinutes(30);

    public DemoSessionCleanupService(IServiceProvider serviceProvider, ILogger<DemoSessionCleanupService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            await Task.Delay(_cleanupInterval, stoppingToken);

            try
            {
                using var scope = _serviceProvider.CreateScope();
                var sessionService = scope.ServiceProvider.GetRequiredService<IDemoSessionService>();
                await sessionService.CleanupExpiredSessionsAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during session cleanup");
            }
        }
    }
}
