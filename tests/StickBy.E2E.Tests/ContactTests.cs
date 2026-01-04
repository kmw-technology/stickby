namespace StickBy.E2E.Tests;

[TestFixture]
[Parallelizable(ParallelScope.Self)]
public class ContactTests : TestBase
{
    [Test]
    public async Task ContactsPage_AfterLogin_ShowsPageHeader()
    {
        await RegisterNewUser();

        await Page.GotoAsync($"{BaseUrl}/Contacts");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        // Check page title is visible
        await Expect(Page.Locator(".page-title")).ToBeVisibleAsync(new() { Timeout = 10000 });
    }

    [Test]
    public async Task ContactsPage_WhenEmpty_ShowsEmptyState()
    {
        await RegisterNewUser();

        await Page.GotoAsync($"{BaseUrl}/Contacts");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        // Check empty state is shown
        await Expect(Page.Locator(".empty-state")).ToBeVisibleAsync(new() { Timeout = 10000 });
    }

    [Test]
    public async Task ContactsPage_HasSearchBar()
    {
        await RegisterNewUser();

        await Page.GotoAsync($"{BaseUrl}/Contacts");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        // Check search bar exists
        await Expect(Page.Locator(".search-bar input")).ToBeVisibleAsync(new() { Timeout = 10000 });
    }

    [Test]
    public async Task ContactsPage_HasAddButton()
    {
        await RegisterNewUser();

        await Page.GotoAsync($"{BaseUrl}/Contacts");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        // Check add button exists
        await Expect(Page.Locator("a.btn-primary[href='/Contacts/Create']")).ToBeVisibleAsync(new() { Timeout = 10000 });
    }

    [Test]
    public async Task ContactsPage_Navigation_FromTabBar()
    {
        await RegisterNewUser();

        // Should be on Home page after registration
        await Expect(Page).ToHaveURLAsync(new Regex(".*/Home"));

        // Navigate to Contacts via tab bar
        await Page.ClickAsync(".tab-bar a[href='/Contacts']");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        // Should now be on contacts page
        await Expect(Page).ToHaveURLAsync(new Regex(".*/Contacts"));
        await Expect(Page.Locator(".page-title")).ToBeVisibleAsync(new() { Timeout = 10000 });
    }
}
