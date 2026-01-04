using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StickBy.Shared.Enums;
using StickBy.Shared.Models.Groups;
using StickBy.Web.Services;

namespace StickBy.Web.Pages.Groups;

[Authorize]
public class DetailsModel : PageModel
{
    private readonly IApiService _apiService;

    public DetailsModel(IApiService apiService)
    {
        _apiService = apiService;
    }

    public GroupDetailDto? Group { get; set; }

    [BindProperty]
    public string? InviteEmail { get; set; }

    public string? SuccessMessage { get; set; }
    public string? ErrorMessage { get; set; }

    public async Task<IActionResult> OnGetAsync(Guid id)
    {
        Group = await _apiService.GetGroupDetailAsync(id);
        if (Group == null)
        {
            return NotFound();
        }
        return Page();
    }

    public async Task<IActionResult> OnPostInviteAsync(Guid id)
    {
        if (string.IsNullOrWhiteSpace(InviteEmail))
        {
            ErrorMessage = "Bitte gib eine E-Mail-Adresse ein.";
            Group = await _apiService.GetGroupDetailAsync(id);
            return Page();
        }

        var success = await _apiService.InviteToGroupAsync(id, InviteEmail);
        if (success)
        {
            SuccessMessage = "Einladung wurde gesendet!";
        }
        else
        {
            ErrorMessage = "Einladung fehlgeschlagen. Benutzer existiert nicht oder ist bereits Mitglied.";
        }

        Group = await _apiService.GetGroupDetailAsync(id);
        return Page();
    }

    public async Task<IActionResult> OnPostLeaveAsync(Guid id)
    {
        var success = await _apiService.LeaveGroupAsync(id);
        if (success)
        {
            return RedirectToPage("./Index");
        }

        ErrorMessage = "Fehler beim Verlassen der Gruppe.";
        Group = await _apiService.GetGroupDetailAsync(id);
        return Page();
    }

    public string GetRoleDisplay(GroupMemberRole role)
    {
        return role switch
        {
            GroupMemberRole.Owner => "Besitzer",
            GroupMemberRole.Admin => "Admin",
            _ => "Mitglied"
        };
    }

    public string GetStatusDisplay(GroupMemberStatus status)
    {
        return status switch
        {
            GroupMemberStatus.Pending => "Ausstehend",
            GroupMemberStatus.Active => "Aktiv",
            _ => status.ToString()
        };
    }
}
