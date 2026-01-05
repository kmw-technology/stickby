using System.ComponentModel.DataAnnotations;

namespace StickBy.Shared.Models.WebSession;

/// <summary>
/// Request from mobile app to authorize a web session.
/// </summary>
public class WebSessionAuthorizeRequest
{
    /// <summary>
    /// The pairing token scanned from QR code.
    /// </summary>
    [Required]
    public string PairingToken { get; set; } = string.Empty;
}
