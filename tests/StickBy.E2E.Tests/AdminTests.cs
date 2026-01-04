namespace StickBy.E2E.Tests;

[TestFixture]
[Parallelizable(ParallelScope.Self)]
public class AdminTests : PageTest
{
    private const string AdminBaseUrl = "https://www.kmw-technology.de/stickby/admin-panel";

    [Test]
    public async Task AdminDashboard_LoadsSuccessfully()
    {
        await Page.GotoAsync(AdminBaseUrl);
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        // Wait for Blazor to render
        await Page.WaitForTimeoutAsync(2000);

        await Expect(Page.Locator("h1:has-text('Dashboard')")).ToBeVisibleAsync(new() { Timeout = 15000 });
    }

    [Test]
    public async Task AdminDashboard_ShowsStatistics()
    {
        await Page.GotoAsync(AdminBaseUrl);
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);
        await Page.WaitForTimeoutAsync(2000);

        // Check stats cards are visible
        await Expect(Page.Locator(".stat-card").First).ToBeVisibleAsync(new() { Timeout = 15000 });
        await Expect(Page.Locator("text=Benutzer gesamt")).ToBeVisibleAsync();
        await Expect(Page.Locator("text=Kontakte gesamt")).ToBeVisibleAsync();
        await Expect(Page.Locator("text=Shares gesamt")).ToBeVisibleAsync();
    }

    [Test]
    public async Task AdminNavigation_UsersPageLoads()
    {
        await Page.GotoAsync(AdminBaseUrl);
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);
        await Page.WaitForTimeoutAsync(2000);

        // Navigate to Users
        await Page.ClickAsync("a:has-text('Benutzer')");
        await Page.WaitForTimeoutAsync(1000);

        await Expect(Page.Locator("h1:has-text('Benutzerverwaltung')")).ToBeVisibleAsync(new() { Timeout = 10000 });
    }

    [Test]
    public async Task AdminNavigation_SharesPageLoads()
    {
        await Page.GotoAsync(AdminBaseUrl);
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);
        await Page.WaitForTimeoutAsync(2000);

        // Navigate to Shares
        await Page.ClickAsync("a:has-text('Shares')");
        await Page.WaitForTimeoutAsync(1000);

        await Expect(Page.Locator("h1:has-text('Shares')")).ToBeVisibleAsync(new() { Timeout = 10000 });
    }

    [Test]
    public async Task AdminNavigation_AuditLogsPageLoads()
    {
        await Page.GotoAsync(AdminBaseUrl);
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);
        await Page.WaitForTimeoutAsync(2000);

        // Navigate to Audit Logs
        await Page.ClickAsync("a:has-text('Audit Logs')");
        await Page.WaitForTimeoutAsync(1000);

        await Expect(Page.Locator("h1:has-text('Audit Logs')")).ToBeVisibleAsync(new() { Timeout = 10000 });
    }

    [Test]
    public async Task AdminUsers_ShowsUserTable()
    {
        await Page.GotoAsync($"{AdminBaseUrl}/users");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);
        await Page.WaitForTimeoutAsync(2000);

        await Expect(Page.Locator("h1:has-text('Benutzerverwaltung')")).ToBeVisibleAsync(new() { Timeout = 10000 });

        // Check search bar is visible
        await Expect(Page.Locator(".search-input")).ToBeVisibleAsync();

        // Check table headers
        await Expect(Page.Locator("th:has-text('Name')")).ToBeVisibleAsync();
        await Expect(Page.Locator("th:has-text('E-Mail')")).ToBeVisibleAsync();
    }

    [Test]
    public async Task AdminLayout_SidebarIsVisible()
    {
        await Page.GotoAsync(AdminBaseUrl);
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);
        await Page.WaitForTimeoutAsync(2000);

        // Check sidebar layout
        await Expect(Page.Locator(".sidebar")).ToBeVisibleAsync(new() { Timeout = 10000 });
        await Expect(Page.Locator("article.content")).ToBeVisibleAsync();

        // Check nav items in sidebar
        await Expect(Page.Locator("a:has-text('Dashboard')")).ToBeVisibleAsync();
        await Expect(Page.Locator("a:has-text('Benutzer')")).ToBeVisibleAsync();
        await Expect(Page.Locator("a:has-text('Shares')")).ToBeVisibleAsync();
    }

    [Test]
    public async Task AdminDashboard_CSSLoadsCorrectly()
    {
        await Page.GotoAsync(AdminBaseUrl);
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);
        await Page.WaitForTimeoutAsync(2000);

        // Check that Bootstrap CSS is loaded (sidebar should have proper styling)
        var sidebar = Page.Locator(".sidebar");
        await Expect(sidebar).ToBeVisibleAsync(new() { Timeout = 10000 });

        // Verify that CSS is applied by checking computed styles
        var bgColor = await sidebar.EvaluateAsync<string>("el => window.getComputedStyle(el).backgroundColor");
        Assert.That(bgColor, Is.Not.EqualTo("rgba(0, 0, 0, 0)"), "CSS should be loaded and applied");
    }
}
