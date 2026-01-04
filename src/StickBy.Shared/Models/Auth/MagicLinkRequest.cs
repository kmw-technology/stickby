using System.ComponentModel.DataAnnotations;

namespace StickBy.Shared.Models.Auth;

public class MagicLinkRequest
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;
}
