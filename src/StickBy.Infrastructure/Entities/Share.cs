namespace StickBy.Infrastructure.Entities;

public class Share
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Token { get; set; } = string.Empty;
    public string? Name { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public int ViewCount { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public virtual User User { get; set; } = null!;
    public virtual ICollection<ShareContact> ShareContacts { get; set; } = new List<ShareContact>();
}
