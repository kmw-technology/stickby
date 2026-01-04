using StickBy.Shared.Models.Contacts;

namespace StickBy.Shared.Models.Groups;

public class GroupShareDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string UserDisplayName { get; set; } = string.Empty;
    public string? Message { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<ContactDto> Contacts { get; set; } = new();
}
