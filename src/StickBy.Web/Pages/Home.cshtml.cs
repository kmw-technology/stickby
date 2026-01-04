using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StickBy.Shared.Models.Groups;
using StickBy.Shared.Models.Shares;
using StickBy.Web.Services;

namespace StickBy.Web.Pages;

[Authorize]
public class HomeModel : PageModel
{
    private readonly IApiService _apiService;

    public HomeModel(IApiService apiService)
    {
        _apiService = apiService;
    }

    public List<GroupDto> PendingInvitations { get; set; } = new();
    public List<ShareDto> RecentShares { get; set; } = new();

    public async Task OnGetAsync()
    {
        PendingInvitations = await _apiService.GetPendingInvitationsAsync();
        RecentShares = await _apiService.GetSharesAsync();
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
