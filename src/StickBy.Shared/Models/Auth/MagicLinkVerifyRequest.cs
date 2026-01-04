using System.ComponentModel.DataAnnotations;

namespace StickBy.Shared.Models.Auth;

public class MagicLinkVerifyRequest
{
    [Required]
    public string Token { get; set; } = string.Empty;
}
