using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StickBy.Shared.Enums;
using StickBy.Shared.Models.Contacts;
using StickBy.Web.Services;

namespace StickBy.Web.Pages.Onboarding;

[Authorize]
public class DetailsModel : PageModel
{
    private readonly IApiService _apiService;

    public DetailsModel(IApiService apiService)
    {
        _apiService = apiService;
    }

    [BindProperty]
    public string? Phone { get; set; }

    [BindProperty]
    public string? Email { get; set; }

    public void OnGet()
    {
    }

    public async Task<IActionResult> OnPostAsync()
    {
        // Create phone contact if provided
        if (!string.IsNullOrWhiteSpace(Phone))
        {
            await _apiService.CreateContactAsync(new CreateContactRequest
            {
                Type = ContactType.Mobile,
                Label = "Privat",
                Value = Phone,
                ReleaseGroups = ReleaseGroup.Family | ReleaseGroup.Friends
            });
        }

        // Create email contact if provided
        if (!string.IsNullOrWhiteSpace(Email))
        {
            await _apiService.CreateContactAsync(new CreateContactRequest
            {
                Type = ContactType.Email,
                Label = "Privat",
                Value = Email,
                ReleaseGroups = ReleaseGroup.Family | ReleaseGroup.Friends
            });
        }

        return RedirectToPage("/Home");
    }

    public IActionResult OnPostSkip()
    {
        return RedirectToPage("/Home");
    }
}
