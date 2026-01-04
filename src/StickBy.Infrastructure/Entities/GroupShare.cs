namespace StickBy.Infrastructure.Entities;

public class GroupShare
{
    public Guid Id { get; set; }
    public Guid GroupId { get; set; }
    public Guid UserId { get; set; }
    public string? Message { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public virtual Group Group { get; set; } = null!;
    public virtual User User { get; set; } = null!;
    public virtual ICollection<GroupShareContact> SharedContacts { get; set; } = new List<GroupShareContact>();
}
