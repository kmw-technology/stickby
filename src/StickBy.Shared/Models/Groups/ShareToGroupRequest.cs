using System.ComponentModel.DataAnnotations;

namespace StickBy.Shared.Models.Groups;

public class ShareToGroupRequest
{
    [Required]
    [MinLength(1)]
    public List<Guid> ContactIds { get; set; } = new();

    [MaxLength(500)]
    public string? Message { get; set; }
}
