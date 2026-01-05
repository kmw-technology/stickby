namespace StickBy.Shared.Models.WebSession;

/// <summary>
/// Response when creating a new web session pairing request.
/// Contains the token to be displayed as QR code.
/// </summary>
public class WebSessionCreateResponse
{
    /// <summary>
    /// Unique session ID.
    /// </summary>
    public Guid SessionId { get; set; }

    /// <summary>
    /// Token to display as QR code for mobile app to scan.
    /// </summary>
    public string PairingToken { get; set; } = string.Empty;

    /// <summary>
    /// When the pairing token expires.
    /// </summary>
    public DateTime ExpiresAt { get; set; }
}
