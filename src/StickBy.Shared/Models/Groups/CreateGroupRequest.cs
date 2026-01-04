using System.ComponentModel.DataAnnotations;

namespace StickBy.Shared.Models.Groups;

public class CreateGroupRequest
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Description { get; set; }
}
