using System.ComponentModel.DataAnnotations;

namespace StickBy.Shared.Models.Profile;

public class UpdateProfileRequest
{
    [Required]
    [MaxLength(100)]
    public string DisplayName { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Bio { get; set; }
}
