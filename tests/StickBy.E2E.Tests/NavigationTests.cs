namespace StickBy.E2E.Tests;

[TestFixture]
[Parallelizable(ParallelScope.Self)]
public class NavigationTests : TestBase
{
    [Test]
    public async Task TabBar_IsVisibleAfterLogin()
    {
        await RegisterNewUser();

        await Expect(Page.Locator(".tab-bar")).ToBeVisibleAsync(new() { Timeout = 10000 });
    }

    [Test]
    public async Task TabBar_HasAllNavigationItems()
    {
        await RegisterNewUser();

        await Expect(Page.Locator(".tab-bar a[href='/Home']")).ToBeVisibleAsync();
        await Expect(Page.Locator(".tab-bar a[href='/Contacts']")).ToBeVisibleAsync();
        await Expect(Page.Locator(".tab-bar a[href='/Groups']")).ToBeVisibleAsync();
        await Expect(Page.Locator(".tab-bar a[href='/Companies']")).ToBeVisibleAsync();
        await Expect(Page.Locator(".tab-bar a[href='/Profile']")).ToBeVisibleAsync();
    }

    [Test]
    public async Task HomePage_LoadsAfterLogin()
    {
        await RegisterNewUser();

        await Expect(Page).ToHaveURLAsync(new Regex(".*/Home"));
        await Expect(Page.Locator(".page-title")).ToBeVisibleAsync(new() { Timeout = 10000 });
    }

    [Test]
    public async Task GroupsPage_LoadsSuccessfully()
    {
        await RegisterNewUser();

        await Page.GotoAsync($"{BaseUrl}/Groups");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        await Expect(Page.Locator(".page-title")).ToBeVisibleAsync(new() { Timeout = 10000 });
    }

    [Test]
    public async Task GroupsPage_WhenEmpty_ShowsEmptyState()
    {
        await RegisterNewUser();

        await Page.GotoAsync($"{BaseUrl}/Groups");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        // New user should have no groups
        await Expect(Page.Locator(".empty-state")).ToBeVisibleAsync(new() { Timeout = 10000 });
    }

    [Test]
    public async Task CompaniesPage_LoadsSuccessfully()
    {
        await RegisterNewUser();

        await Page.GotoAsync($"{BaseUrl}/Companies");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        await Expect(Page.Locator(".page-title")).ToBeVisibleAsync(new() { Timeout = 10000 });
    }

    [Test]
    public async Task ProfilePage_LoadsSuccessfully()
    {
        await RegisterNewUser();

        await Page.GotoAsync($"{BaseUrl}/Profile");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        await Expect(Page.Locator(".page-title")).ToBeVisibleAsync(new() { Timeout = 10000 });
    }

    [Test]
    public async Task Header_ShowsLogoAndLogoutButton()
    {
        await RegisterNewUser();

        await Expect(Page.Locator(".app-header .logo")).ToBeVisibleAsync();
        await Expect(Page.Locator(".app-header button[type='submit']")).ToBeVisibleAsync(); // Logout button
    }

    [Test]
    public async Task Logout_RedirectsToLandingPage()
    {
        await RegisterNewUser();

        // Click logout button
        await Page.Locator(".app-header form button[type='submit']").ClickAsync();
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        // Should be redirected to landing page (Index)
        await Expect(Page.Locator(".hero")).ToBeVisibleAsync(new() { Timeout = 10000 });
    }
}
