using StickBy.Shared.Models.Contacts;

namespace StickBy.Shared.Models.Profile;

public class ProfileDto
{
    public Guid Id { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public string? Bio { get; set; }
    public Dictionary<string, List<ContactDto>> ContactsByCategory { get; set; } = new();
}
