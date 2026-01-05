namespace StickBy.Shared.Models.WebSession;

/// <summary>
/// Represents an active web session for display in the app.
/// </summary>
public class WebSessionDto
{
    public Guid Id { get; set; }

    /// <summary>
    /// Friendly name for the session (e.g. "Chrome on Windows").
    /// </summary>
    public string? DeviceName { get; set; }

    /// <summary>
    /// Browser/client user agent string.
    /// </summary>
    public string? UserAgent { get; set; }

    /// <summary>
    /// IP address of the web client.
    /// </summary>
    public string? IpAddress { get; set; }

    /// <summary>
    /// When the session was authorized.
    /// </summary>
    public DateTime AuthorizedAt { get; set; }

    /// <summary>
    /// Last activity timestamp.
    /// </summary>
    public DateTime? LastActivityAt { get; set; }

    /// <summary>
    /// Whether the session is currently active.
    /// </summary>
    public bool IsActive { get; set; }
}
