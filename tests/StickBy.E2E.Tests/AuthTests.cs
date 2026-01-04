using Microsoft.Playwright;

namespace StickBy.E2E.Tests;

[TestFixture]
[Parallelizable(ParallelScope.Self)]
public class AuthTests : TestBase
{
    [Test]
    public async Task LandingPage_ShowsLoginAndRegisterButtons()
    {
        await Page.GotoAsync(BaseUrl);
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        // Check for register and login links in the header navigation
        var registerButton = Page.Locator(".app-header nav a[href='/Auth/Register']");
        var loginButton = Page.Locator(".app-header nav a[href='/Auth/Login']");

        await Expect(registerButton).ToBeVisibleAsync();
        await Expect(loginButton).ToBeVisibleAsync();
    }

    [Test]
    public async Task LandingPage_ShowsHeroSection()
    {
        await Page.GotoAsync(BaseUrl);
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        await Expect(Page.Locator(".hero h1")).ToBeVisibleAsync();
        await Expect(Page.Locator(".hero .tagline")).ToBeVisibleAsync();
        await Expect(Page.Locator(".features")).ToBeVisibleAsync();
    }

    [Test]
    public async Task Registration_PageLoads()
    {
        await Page.GotoAsync($"{BaseUrl}/Auth/Register");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        await Expect(Page.Locator("h1")).ToBeVisibleAsync();
        await Expect(Page.Locator("#DisplayName")).ToBeVisibleAsync();
        await Expect(Page.Locator("#Email")).ToBeVisibleAsync();
        await Expect(Page.Locator("#Password")).ToBeVisibleAsync();
        await Expect(Page.Locator("button[type='submit']")).ToBeVisibleAsync();
    }

    [Test]
    public async Task Registration_WithValidData_RedirectsToHome()
    {
        var email = $"test-{Guid.NewGuid():N}@example.com";

        await Page.GotoAsync($"{BaseUrl}/Auth/Register");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        await Page.FillAsync("#DisplayName", "Test User");
        await Page.FillAsync("#Email", email);
        await Page.FillAsync("#Password", "TestPass123");
        await Page.ClickAsync("button[type='submit']");

        await Page.WaitForURLAsync(url => url.Contains("/Home"), new() { Timeout = 15000 });
        await Expect(Page.Locator(".page-title")).ToBeVisibleAsync();
    }

    [Test]
    public async Task Registration_WithExistingEmail_ShowsError()
    {
        // First register a user
        var email = await RegisterNewUser();
        await Logout();

        // Try to register again with the same email
        await Page.GotoAsync($"{BaseUrl}/Auth/Register");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        await Page.FillAsync("#DisplayName", "Another User");
        await Page.FillAsync("#Email", email);
        await Page.FillAsync("#Password", "TestPass123");
        await Page.ClickAsync("button[type='submit']");

        // Wait for the page to process
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        // Should show error message
        await Expect(Page.Locator(".error-message")).ToBeVisibleAsync(new() { Timeout = 15000 });
    }

    [Test]
    public async Task Login_PageLoads()
    {
        await Page.GotoAsync($"{BaseUrl}/Auth/Login");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        await Expect(Page.Locator("h1")).ToBeVisibleAsync();
        await Expect(Page.Locator("#Email")).ToBeVisibleAsync();
        await Expect(Page.Locator("#Password")).ToBeVisibleAsync();
        await Expect(Page.Locator("button[type='submit']")).ToBeVisibleAsync();
    }

    [Test]
    public async Task Login_WithValidCredentials_RedirectsToHome()
    {
        var email = await RegisterNewUser();
        await Logout();

        await Page.GotoAsync($"{BaseUrl}/Auth/Login");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        await Page.FillAsync("#Email", email);
        await Page.FillAsync("#Password", "TestPass123");
        await Page.ClickAsync("button[type='submit']");

        await Page.WaitForURLAsync(url => url.Contains("/Home"), new() { Timeout = 15000 });
        await Expect(Page.Locator(".page-title")).ToBeVisibleAsync();
    }

    [Test]
    public async Task Login_WithInvalidCredentials_ShowsError()
    {
        await Page.GotoAsync($"{BaseUrl}/Auth/Login");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        await Page.FillAsync("#Email", "nonexistent@example.com");
        await Page.FillAsync("#Password", "wrongpassword");
        await Page.ClickAsync("button[type='submit']");

        await Expect(Page.Locator(".error-message")).ToBeVisibleAsync(new() { Timeout = 10000 });
    }

    [Test]
    public async Task Login_HasLinkToRegister()
    {
        await Page.GotoAsync($"{BaseUrl}/Auth/Login");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        // Look for register link in the main content area (not header)
        var registerLink = Page.Locator("main a[href='/Auth/Register'], .auth-container a[href='/Auth/Register']").First;
        await Expect(registerLink).ToBeVisibleAsync();
    }

    [Test]
    public async Task Register_HasLinkToLogin()
    {
        await Page.GotoAsync($"{BaseUrl}/Auth/Register");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        // Look for login link in the main content area (not header)
        var loginLink = Page.Locator("main a[href='/Auth/Login'], .auth-container a[href='/Auth/Login']").First;
        await Expect(loginLink).ToBeVisibleAsync();
    }
}
