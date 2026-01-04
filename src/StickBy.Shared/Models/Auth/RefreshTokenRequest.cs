using System.ComponentModel.DataAnnotations;

namespace StickBy.Shared.Models.Auth;

public class RefreshTokenRequest
{
    [Required]
    public string RefreshToken { get; set; } = string.Empty;
}
