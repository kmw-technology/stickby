using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StickBy.Shared.Enums;
using StickBy.Shared.Models.Contacts;
using StickBy.Shared.Models.Profile;
using StickBy.Web.Services;

namespace StickBy.Web.Pages.Profile;

[Authorize]
public class ReleaseGroupsModel : PageModel
{
    private readonly IApiService _apiService;

    public ReleaseGroupsModel(IApiService apiService)
    {
        _apiService = apiService;
    }

    public List<ContactDto> Contacts { get; set; } = new();
    public Dictionary<string, List<ContactDto>> ContactsByCategory { get; set; } = new();

    [BindProperty]
    public Dictionary<Guid, ReleaseGroup> ContactReleaseGroups { get; set; } = new();

    public string? SuccessMessage { get; set; }

    public async Task OnGetAsync()
    {
        await LoadContactsAsync();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        var updates = ContactReleaseGroups.Select(kvp => new UpdateReleaseGroupsRequest
        {
            ContactId = kvp.Key,
            ReleaseGroups = kvp.Value
        }).ToList();

        var success = await _apiService.UpdateReleaseGroupsAsync(updates);
        if (success)
        {
            SuccessMessage = "Freigabegruppierungen erfolgreich aktualisiert!";
        }

        await LoadContactsAsync();
        return Page();
    }

    private async Task LoadContactsAsync()
    {
        Contacts = await _apiService.GetContactsAsync();

        ContactsByCategory = Contacts
            .GroupBy(c => GetCategoryKey(c.Type))
            .ToDictionary(g => g.Key, g => g.OrderBy(c => c.SortOrder).ToList());

        // Initialize the release groups dictionary
        foreach (var contact in Contacts)
        {
            if (!ContactReleaseGroups.ContainsKey(contact.Id))
            {
                ContactReleaseGroups[contact.Id] = contact.ReleaseGroups;
            }
        }
    }

    private string GetCategoryKey(ContactType type)
    {
        var typeValue = (int)type;
        return typeValue switch
        {
            >= 100 and < 200 => "personal",
            >= 200 and < 300 => "private",
            >= 300 and < 400 => "business",
            >= 400 and < 500 => "social",
            >= 500 and < 600 => "gaming",
            _ => "general"
        };
    }
}
