using StickBy.Shared.Enums;

namespace StickBy.Infrastructure.Entities;

public class GroupMember
{
    public Guid GroupId { get; set; }
    public Guid UserId { get; set; }
    public GroupMemberRole Role { get; set; } = GroupMemberRole.Member;
    public GroupMemberStatus Status { get; set; } = GroupMemberStatus.Pending;
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public virtual Group Group { get; set; } = null!;
    public virtual User User { get; set; } = null!;
}
