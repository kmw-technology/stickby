using StickBy.Shared.Enums;

namespace StickBy.Shared.Models.Contacts;

public class ContactDto
{
    public Guid Id { get; set; }
    public ContactType Type { get; set; }
    public string Label { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
    public int SortOrder { get; set; }
    public ReleaseGroup ReleaseGroups { get; set; } = ReleaseGroup.All;
}
