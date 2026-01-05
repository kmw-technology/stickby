using StickBy.Shared.Models.Auth;

namespace StickBy.Shared.Models.WebSession;

/// <summary>
/// Response when checking the status of a web session.
/// </summary>
public class WebSessionStatusResponse
{
    /// <summary>
    /// Current status of the session.
    /// </summary>
    public WebSessionStatus Status { get; set; }

    /// <summary>
    /// Auth tokens if session is authorized. Null otherwise.
    /// </summary>
    public AuthResponse? Auth { get; set; }
}

public enum WebSessionStatus
{
    /// <summary>
    /// Session is waiting to be authorized by mobile app.
    /// </summary>
    Pending,

    /// <summary>
    /// Pairing token has expired without authorization.
    /// </summary>
    Expired,

    /// <summary>
    /// Session has been authorized and is active.
    /// </summary>
    Authorized,

    /// <summary>
    /// Session has been invalidated/logged out.
    /// </summary>
    Invalidated,

    /// <summary>
    /// Session not found.
    /// </summary>
    NotFound
}
