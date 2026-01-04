using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StickBy.Shared.Models.Groups;
using StickBy.Web.Services;

namespace StickBy.Web.Pages.Groups;

[Authorize]
public class IndexModel : PageModel
{
    private readonly IApiService _apiService;

    public IndexModel(IApiService apiService)
    {
        _apiService = apiService;
    }

    public List<GroupDto> Groups { get; set; } = new();

    public async Task OnGetAsync()
    {
        Groups = await _apiService.GetGroupsAsync();
    }
}
