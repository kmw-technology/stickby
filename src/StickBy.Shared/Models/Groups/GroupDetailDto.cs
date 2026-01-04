using StickBy.Shared.Enums;

namespace StickBy.Shared.Models.Groups;

public class GroupDetailDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? CoverImageUrl { get; set; }
    public Guid CreatedByUserId { get; set; }
    public string CreatedByUserName { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public GroupMemberRole? MyRole { get; set; }
    public GroupMemberStatus? MyStatus { get; set; }
    public List<GroupMemberDto> Members { get; set; } = new();
    public List<GroupShareDto> RecentShares { get; set; } = new();
}
