using Microsoft.AspNetCore.Identity;

namespace StickBy.Infrastructure.Entities;

public class User : IdentityUser<Guid>
{
    public string DisplayName { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public string? Bio { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? LastLoginAt { get; set; }

    // Navigation properties
    public virtual ICollection<ContactInfo> Contacts { get; set; } = new List<ContactInfo>();
    public virtual ICollection<Share> Shares { get; set; } = new List<Share>();
    public virtual ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();
    public virtual ICollection<MagicLink> MagicLinks { get; set; } = new List<MagicLink>();
    public virtual ICollection<GroupMember> GroupMemberships { get; set; } = new List<GroupMember>();
    public virtual ICollection<Group> CreatedGroups { get; set; } = new List<Group>();
    public virtual ICollection<GroupShare> GroupShares { get; set; } = new List<GroupShare>();
    public virtual ICollection<WebSession> WebSessions { get; set; } = new List<WebSession>();
}
