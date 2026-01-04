using System.ComponentModel.DataAnnotations;

namespace StickBy.Shared.Models.Shares;

public class CreateShareRequest
{
    [MaxLength(100)]
    public string? Name { get; set; }

    public DateTime? ExpiresAt { get; set; }

    [Required]
    [MinLength(1)]
    public List<Guid> ContactIds { get; set; } = new();
}
