using System.ComponentModel.DataAnnotations;

namespace StickBy.Shared.Models.Groups;

public class InviteToGroupRequest
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;
}
