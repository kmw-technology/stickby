using System.ComponentModel.DataAnnotations;
using StickBy.Shared.Enums;

namespace StickBy.Shared.Models.Contacts;

public class CreateContactRequest
{
    [Required]
    public ContactType Type { get; set; }

    [Required]
    [MaxLength(50)]
    public string Label { get; set; } = string.Empty;

    [Required]
    [MaxLength(500)]
    public string Value { get; set; } = string.Empty;

    public int SortOrder { get; set; }

    public ReleaseGroup ReleaseGroups { get; set; } = ReleaseGroup.All;
}
