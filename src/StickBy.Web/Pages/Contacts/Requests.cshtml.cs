using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StickBy.Shared.Models.Groups;
using StickBy.Web.Services;

namespace StickBy.Web.Pages.Contacts;

[Authorize]
public class RequestsModel : PageModel
{
    private readonly IApiService _apiService;

    public RequestsModel(IApiService apiService)
    {
        _apiService = apiService;
    }

    public List<GroupDto> PendingInvitations { get; set; } = new();

    public async Task OnGetAsync()
    {
        PendingInvitations = await _apiService.GetPendingInvitationsAsync();
    }

    public async Task<IActionResult> OnPostAcceptAsync(Guid id)
    {
        await _apiService.JoinGroupAsync(id);
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostDeclineAsync(Guid id)
    {
        await _apiService.DeclineInvitationAsync(id);
        return RedirectToPage();
    }
}
