using StickBy.Shared.Enums;

namespace StickBy.Shared.Models.Groups;

public class GroupMemberDto
{
    public Guid UserId { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public GroupMemberRole Role { get; set; }
    public GroupMemberStatus Status { get; set; }
    public DateTime JoinedAt { get; set; }
}
