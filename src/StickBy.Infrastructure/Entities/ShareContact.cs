namespace StickBy.Infrastructure.Entities;

public class ShareContact
{
    public Guid ShareId { get; set; }
    public Guid ContactInfoId { get; set; }

    // Navigation properties
    public virtual Share Share { get; set; } = null!;
    public virtual ContactInfo ContactInfo { get; set; } = null!;
}
