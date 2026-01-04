using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StickBy.Shared.Enums;
using StickBy.Shared.Models.Contacts;
using StickBy.Shared.Models.Profile;
using StickBy.Web.Services;

namespace StickBy.Web.Pages.Contacts;

[Authorize]
public class AssignGroupsModel : PageModel
{
    private readonly IApiService _apiService;

    public AssignGroupsModel(IApiService apiService)
    {
        _apiService = apiService;
    }

    public List<ContactDto> Contacts { get; set; } = new();

    [BindProperty]
    public List<Guid> SelectedContactIds { get; set; } = new();

    [BindProperty]
    public ReleaseGroup TargetGroup { get; set; }

    [BindProperty]
    public string Action { get; set; } = "add";

    public string? SuccessMessage { get; set; }

    public async Task OnGetAsync()
    {
        Contacts = await _apiService.GetContactsAsync();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (SelectedContactIds.Count == 0)
        {
            ModelState.AddModelError(string.Empty, "Bitte wähle mindestens einen Kontakt aus.");
            await OnGetAsync();
            return Page();
        }

        // Get current contacts to preserve their existing release groups
        var allContacts = await _apiService.GetContactsAsync();
        var updates = new List<UpdateReleaseGroupsRequest>();

        foreach (var contactId in SelectedContactIds)
        {
            var contact = allContacts.FirstOrDefault(c => c.Id == contactId);
            if (contact == null) continue;

            ReleaseGroup newGroups;
            if (Action == "add")
            {
                newGroups = contact.ReleaseGroups | TargetGroup;
            }
            else // remove
            {
                newGroups = contact.ReleaseGroups & ~TargetGroup;
            }

            updates.Add(new UpdateReleaseGroupsRequest
            {
                ContactId = contactId,
                ReleaseGroups = newGroups
            });
        }

        var success = await _apiService.UpdateReleaseGroupsAsync(updates);
        if (success)
        {
            var actionText = Action == "add" ? "hinzugefügt" : "entfernt";
            SuccessMessage = $"{SelectedContactIds.Count} Kontakte wurden erfolgreich aktualisiert!";
        }

        Contacts = await _apiService.GetContactsAsync();
        SelectedContactIds.Clear();
        return Page();
    }
}
