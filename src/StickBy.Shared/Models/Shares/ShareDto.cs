using StickBy.Shared.Models.Contacts;

namespace StickBy.Shared.Models.Shares;

public class ShareDto
{
    public Guid Id { get; set; }
    public string Token { get; set; } = string.Empty;
    public string? Name { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public int ViewCount { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<Guid> ContactIds { get; set; } = new();
}

public class ShareViewDto
{
    public string? OwnerDisplayName { get; set; }
    public List<ContactDto> Contacts { get; set; } = new();
}
