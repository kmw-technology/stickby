using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StickBy.Shared.Models.Groups;
using StickBy.Web.Services;

namespace StickBy.Web.Pages.Groups;

[Authorize]
public class CreateModel : PageModel
{
    private readonly IApiService _apiService;

    public CreateModel(IApiService apiService)
    {
        _apiService = apiService;
    }

    [BindProperty]
    public string Name { get; set; } = string.Empty;

    [BindProperty]
    public string? Description { get; set; }

    public void OnGet()
    {
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (string.IsNullOrWhiteSpace(Name))
        {
            ModelState.AddModelError(nameof(Name), "Gruppenname ist erforderlich");
            return Page();
        }

        var result = await _apiService.CreateGroupAsync(new CreateGroupRequest
        {
            Name = Name,
            Description = Description
        });

        if (result != null)
        {
            return RedirectToPage("./Details", new { id = result.Id });
        }

        ModelState.AddModelError(string.Empty, "Fehler beim Erstellen der Gruppe");
        return Page();
    }
}
