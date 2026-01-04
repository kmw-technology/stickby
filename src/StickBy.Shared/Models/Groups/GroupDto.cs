using StickBy.Shared.Enums;

namespace StickBy.Shared.Models.Groups;

public class GroupDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? CoverImageUrl { get; set; }
    public int MemberCount { get; set; }
    public GroupMemberRole? MyRole { get; set; }
    public GroupMemberStatus? MyStatus { get; set; }
    public DateTime CreatedAt { get; set; }
}
