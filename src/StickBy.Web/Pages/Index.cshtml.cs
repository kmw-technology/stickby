using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace StickBy.Web.Pages;

public class IndexModel : PageModel
{
    public IActionResult OnGet()
    {
        // Like WhatsApp Web: redirect to QR login for unauthenticated users
        if (User.Identity?.IsAuthenticated == true)
        {
            return RedirectToPage("/Home");
        }

        return RedirectToPage("/Auth/Login");
    }
}
