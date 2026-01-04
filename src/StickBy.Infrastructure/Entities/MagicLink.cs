namespace StickBy.Infrastructure.Entities;

public class MagicLink
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool IsUsed { get; set; }
    public DateTime? UsedAt { get; set; }

    public bool IsExpired => DateTime.UtcNow >= ExpiresAt;
    public bool IsValid => !IsUsed && !IsExpired;

    // Navigation properties
    public virtual User User { get; set; } = null!;
}
