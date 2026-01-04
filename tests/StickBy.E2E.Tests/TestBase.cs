namespace StickBy.E2E.Tests;

public class TestBase : PageTest
{
    // Production URLs
    protected const string BaseUrl = "https://www.kmw-technology.de/stickby/website";
    protected const string AdminBaseUrl = "https://www.kmw-technology.de/stickby/admin-panel";
    protected const string ApiBaseUrl = "https://www.kmw-technology.de/stickby/backend";

    protected async Task<string> RegisterNewUser()
    {
        var email = $"test-{Guid.NewGuid():N}@example.com";
        var password = "TestPass123";

        await Page.GotoAsync($"{BaseUrl}/Auth/Register");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        await Page.FillAsync("#DisplayName", "Test User");
        await Page.FillAsync("#Email", email);
        await Page.FillAsync("#Password", password);
        await Page.ClickAsync("button[type='submit']");

        // Wait for redirect to Home page
        await Page.WaitForURLAsync(url => url.Contains("/Home"), new() { Timeout = 10000 });
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        return email;
    }

    protected async Task Login(string email, string password = "TestPass123")
    {
        await Page.GotoAsync($"{BaseUrl}/Auth/Login");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        await Page.FillAsync("#Email", email);
        await Page.FillAsync("#Password", password);
        await Page.ClickAsync("button[type='submit']");

        await Page.WaitForURLAsync(url => url.Contains("/Home"), new() { Timeout = 10000 });
    }

    protected async Task Logout()
    {
        await Page.GotoAsync($"{BaseUrl}/Auth/Logout");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);
    }
}
