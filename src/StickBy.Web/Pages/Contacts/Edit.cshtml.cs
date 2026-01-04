using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StickBy.Shared.Enums;
using StickBy.Shared.Models.Contacts;
using StickBy.Web.Services;

namespace StickBy.Web.Pages.Contacts;

[Authorize]
public class EditModel : PageModel
{
    private readonly IApiService _apiService;

    public EditModel(IApiService apiService)
    {
        _apiService = apiService;
    }

    [BindProperty]
    public Guid ContactId { get; set; }

    [BindProperty]
    public UpdateContactRequest Contact { get; set; } = new();

    [BindProperty]
    public bool ReleaseFamily { get; set; }

    [BindProperty]
    public bool ReleaseFriends { get; set; }

    [BindProperty]
    public bool ReleaseBusiness { get; set; }

    [BindProperty]
    public bool ReleaseLeisure { get; set; }

    public async Task<IActionResult> OnGetAsync(Guid id)
    {
        var contact = await _apiService.GetContactAsync(id);
        if (contact == null)
        {
            return NotFound();
        }

        ContactId = id;
        Contact = new UpdateContactRequest
        {
            Type = contact.Type,
            Label = contact.Label,
            Value = contact.Value,
            SortOrder = contact.SortOrder,
            ReleaseGroups = contact.ReleaseGroups
        };

        // Set checkbox states
        ReleaseFamily = contact.ReleaseGroups.HasFlag(ReleaseGroup.Family);
        ReleaseFriends = contact.ReleaseGroups.HasFlag(ReleaseGroup.Friends);
        ReleaseBusiness = contact.ReleaseGroups.HasFlag(ReleaseGroup.Business);
        ReleaseLeisure = contact.ReleaseGroups.HasFlag(ReleaseGroup.Leisure);

        return Page();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid)
        {
            return Page();
        }

        // Build ReleaseGroups from checkboxes
        var releaseGroups = ReleaseGroup.None;
        if (ReleaseFamily) releaseGroups |= ReleaseGroup.Family;
        if (ReleaseFriends) releaseGroups |= ReleaseGroup.Friends;
        if (ReleaseBusiness) releaseGroups |= ReleaseGroup.Business;
        if (ReleaseLeisure) releaseGroups |= ReleaseGroup.Leisure;

        Contact.ReleaseGroups = releaseGroups;

        var result = await _apiService.UpdateContactAsync(ContactId, Contact);
        if (result != null)
        {
            return RedirectToPage("./Index");
        }

        ModelState.AddModelError(string.Empty, "Fehler beim Aktualisieren des Kontakts");
        return Page();
    }

    public IEnumerable<(ContactType Type, string Name, string Category)> GetContactTypes()
    {
        return new[]
        {
            // Personal
            (ContactType.Nationality, "Nationalität", "personal"),
            (ContactType.MaritalStatus, "Familienstand", "personal"),
            (ContactType.PlaceOfBirth, "Geburtsort", "personal"),
            (ContactType.Education, "Bildung", "personal"),
            (ContactType.Birthday, "Geburtstag", "personal"),
            // Private
            (ContactType.Email, "E-Mail", "private"),
            (ContactType.Phone, "Telefon", "private"),
            (ContactType.Mobile, "Mobil", "private"),
            (ContactType.Address, "Adresse", "private"),
            (ContactType.EmergencyContact, "Notfallkontakt", "private"),
            // Business
            (ContactType.Company, "Firma", "business"),
            (ContactType.Position, "Position", "business"),
            (ContactType.BusinessEmail, "Geschäfts-E-Mail", "business"),
            (ContactType.BusinessPhone, "Geschäftstelefon", "business"),
            // Social
            (ContactType.Facebook, "Facebook", "social"),
            (ContactType.Instagram, "Instagram", "social"),
            (ContactType.LinkedIn, "LinkedIn", "social"),
            (ContactType.Twitter, "Twitter/X", "social"),
            (ContactType.TikTok, "TikTok", "social"),
            (ContactType.Snapchat, "Snapchat", "social"),
            (ContactType.Xing, "Xing", "social"),
            (ContactType.GitHub, "GitHub", "social"),
            // Gaming
            (ContactType.Steam, "Steam", "gaming"),
            (ContactType.Discord, "Discord", "gaming"),
            // Other
            (ContactType.Website, "Website", "other"),
            (ContactType.Custom, "Benutzerdefiniert", "other")
        };
    }
}
