using StickBy.Shared.Enums;

namespace StickBy.Infrastructure.Entities;

public class ContactInfo
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public ContactType Type { get; set; }
    public string Label { get; set; } = string.Empty;
    public string EncryptedValue { get; set; } = string.Empty;
    public int SortOrder { get; set; }
    public ReleaseGroup ReleaseGroups { get; set; } = ReleaseGroup.All;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    public virtual User User { get; set; } = null!;
    public virtual ICollection<ShareContact> ShareContacts { get; set; } = new List<ShareContact>();
}
