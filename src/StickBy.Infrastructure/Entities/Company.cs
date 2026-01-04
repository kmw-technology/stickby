namespace StickBy.Infrastructure.Entities;

public class Company
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? LogoUrl { get; set; }
    public string? BackgroundImageUrl { get; set; }
    public bool IsContractor { get; set; }
    public int FollowerCount { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
