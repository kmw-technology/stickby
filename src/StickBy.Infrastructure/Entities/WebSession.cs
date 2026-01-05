namespace StickBy.Infrastructure.Entities;

/// <summary>
/// Represents a web session that can be authorized by a mobile app (like WhatsApp Web).
/// The website generates a session with a pairing token, displays it as QR code,
/// and waits for the mobile app to authorize it.
/// </summary>
public class WebSession
{
    public Guid Id { get; set; }

    /// <summary>
    /// The user who authorized this session. Null until authorized.
    /// </summary>
    public Guid? UserId { get; set; }

    /// <summary>
    /// Unique token displayed as QR code for pairing.
    /// </summary>
    public string PairingToken { get; set; } = string.Empty;

    /// <summary>
    /// Access token granted after authorization.
    /// </summary>
    public string? AccessToken { get; set; }

    /// <summary>
    /// Refresh token granted after authorization.
    /// </summary>
    public string? RefreshToken { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// When the pairing token expires (short-lived, e.g. 5 minutes).
    /// </summary>
    public DateTime PairingExpiresAt { get; set; }

    /// <summary>
    /// When the session was authorized by the mobile app.
    /// </summary>
    public DateTime? AuthorizedAt { get; set; }

    /// <summary>
    /// When the session expires (after authorization, e.g. 30 days).
    /// </summary>
    public DateTime? SessionExpiresAt { get; set; }

    /// <summary>
    /// When the session was invalidated/logged out.
    /// </summary>
    public DateTime? InvalidatedAt { get; set; }

    /// <summary>
    /// Last activity timestamp for session management.
    /// </summary>
    public DateTime? LastActivityAt { get; set; }

    /// <summary>
    /// Browser/client user agent string.
    /// </summary>
    public string? UserAgent { get; set; }

    /// <summary>
    /// IP address of the web client.
    /// </summary>
    public string? IpAddress { get; set; }

    /// <summary>
    /// Friendly name for the session (e.g. "Chrome on Windows").
    /// </summary>
    public string? DeviceName { get; set; }

    // Computed properties
    public bool IsPairingExpired => DateTime.UtcNow >= PairingExpiresAt;
    public bool IsAuthorized => AuthorizedAt != null && UserId != null;
    public bool IsSessionExpired => SessionExpiresAt != null && DateTime.UtcNow >= SessionExpiresAt;
    public bool IsInvalidated => InvalidatedAt != null;
    public bool IsActive => IsAuthorized && !IsSessionExpired && !IsInvalidated;
    public bool IsPendingAuthorization => !IsAuthorized && !IsPairingExpired;

    // Navigation properties
    public virtual User? User { get; set; }
}
