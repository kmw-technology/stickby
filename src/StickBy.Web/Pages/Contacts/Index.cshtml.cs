using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StickBy.Shared.Enums;
using StickBy.Shared.Models.Contacts;
using StickBy.Web.Services;

namespace StickBy.Web.Pages.Contacts;

[Authorize]
public class IndexModel : PageModel
{
    private readonly IApiService _apiService;
    private readonly ILocalizationService _l;

    public IndexModel(IApiService apiService, ILocalizationService l)
    {
        _apiService = apiService;
        _l = l;
    }

    public List<ContactDto> Contacts { get; set; } = new();
    public int PendingRequestsCount { get; set; }

    public IEnumerable<IGrouping<string, ContactDto>> GroupedContacts => Contacts
        .Where(c => string.IsNullOrEmpty(SearchQuery) ||
            c.Label.Contains(SearchQuery, StringComparison.OrdinalIgnoreCase) ||
            c.Value.Contains(SearchQuery, StringComparison.OrdinalIgnoreCase))
        .GroupBy(c => GetCategoryName(c.Type))
        .OrderBy(g => GetCategoryOrder(g.Key));

    [BindProperty(SupportsGet = true)]
    public string? SearchQuery { get; set; }

    public async Task OnGetAsync()
    {
        var contactsTask = _apiService.GetContactsAsync();
        var invitationsTask = _apiService.GetPendingInvitationsAsync();

        await Task.WhenAll(contactsTask, invitationsTask);

        Contacts = contactsTask.Result;
        PendingRequestsCount = invitationsTask.Result.Count;
    }

    public async Task<IActionResult> OnPostDeleteAsync(Guid id)
    {
        await _apiService.DeleteContactAsync(id);
        return RedirectToPage();
    }

    private string GetCategoryName(ContactType type)
    {
        var typeValue = (int)type;
        return typeValue switch
        {
            >= 100 and < 200 => _l["category.personal"],
            >= 200 and < 300 => _l["category.private"],
            >= 300 and < 400 => _l["category.business"],
            >= 400 and < 500 => _l["category.social"],
            >= 500 and < 600 => _l["category.gaming"],
            _ => _l.CurrentLanguage == "de" ? "Allgemein" : "General"
        };
    }

    private int GetCategoryOrder(string category)
    {
        if (category == _l["category.personal"]) return 0;
        if (category == _l["category.private"]) return 1;
        if (category == _l["category.business"]) return 2;
        if (category == _l["category.social"]) return 3;
        if (category == _l["category.gaming"]) return 4;
        return 5;
    }
}
