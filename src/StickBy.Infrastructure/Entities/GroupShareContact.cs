namespace StickBy.Infrastructure.Entities;

public class GroupShareContact
{
    public Guid GroupShareId { get; set; }
    public Guid ContactInfoId { get; set; }

    // Navigation properties
    public virtual GroupShare GroupShare { get; set; } = null!;
    public virtual ContactInfo ContactInfo { get; set; } = null!;
}
