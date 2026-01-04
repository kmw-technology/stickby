namespace StickBy.E2E.Tests;

[TestFixture]
[Parallelizable(ParallelScope.Self)]
public class ResponsiveTests : TestBase
{
    private static readonly (int Width, int Height, string Name)[] MobileViewports = new[]
    {
        (375, 667, "iPhone SE"),
        (390, 844, "iPhone 12/13"),
        (414, 896, "iPhone XR/11"),
        (360, 800, "Samsung Galaxy S20"),
        (412, 915, "Pixel 5")
    };

    [Test]
    public async Task LandingPage_Mobile_LayoutIsResponsive()
    {
        await Page.SetViewportSizeAsync(390, 844);
        await Page.GotoAsync(BaseUrl);
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        await Expect(Page.Locator(".app-header")).ToBeVisibleAsync();
        await Expect(Page.Locator(".app-header .logo")).ToBeVisibleAsync();
        await Expect(Page.Locator(".hero h1")).ToBeVisibleAsync();
        await Expect(Page.Locator(".features")).ToBeVisibleAsync();
    }

    [Test]
    public async Task LoginPage_Mobile_FormIsUsable()
    {
        await Page.SetViewportSizeAsync(375, 667);
        await Page.GotoAsync($"{BaseUrl}/Auth/Login");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        var emailInput = Page.Locator("#Email");
        await Expect(emailInput).ToBeVisibleAsync();

        var passwordInput = Page.Locator("#Password");
        await Expect(passwordInput).ToBeVisibleAsync();

        var submitButton = Page.Locator("button[type='submit']");
        await Expect(submitButton).ToBeVisibleAsync();
    }

    [Test]
    public async Task HomePage_Mobile_TabBarIsVisible()
    {
        await Page.SetViewportSizeAsync(390, 844);
        await RegisterNewUser();

        await Expect(Page.Locator(".tab-bar")).ToBeVisibleAsync();
        await Expect(Page.Locator(".page-title")).ToBeVisibleAsync();
    }

    [Test]
    public async Task ContactsPage_Mobile_LayoutIsUsable()
    {
        await Page.SetViewportSizeAsync(375, 667);
        await RegisterNewUser();

        await Page.GotoAsync($"{BaseUrl}/Contacts");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        await Expect(Page.Locator(".page-title")).ToBeVisibleAsync();
        await Expect(Page.Locator(".search-bar")).ToBeVisibleAsync();
    }

    [Test]
    public async Task Header_Mobile_LogoIsVisible()
    {
        await Page.SetViewportSizeAsync(360, 800);
        await RegisterNewUser();

        await Expect(Page.Locator(".app-header .logo")).ToBeVisibleAsync();
    }

    [Test]
    [TestCaseSource(nameof(GetMobileViewports))]
    public async Task LandingPage_MultipleDevices_IsUsable((int Width, int Height, string Name) viewport)
    {
        await Page.SetViewportSizeAsync(viewport.Width, viewport.Height);
        await Page.GotoAsync(BaseUrl);
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        await Expect(Page.Locator(".app-header .logo")).ToBeVisibleAsync();
        await Expect(Page.Locator(".hero")).ToBeVisibleAsync();

        var bodyWidth = await Page.EvaluateAsync<int>("() => document.body.scrollWidth");
        Assert.That(bodyWidth, Is.LessThanOrEqualTo(viewport.Width + 20));
    }

    [Test]
    public async Task TouchTarget_Mobile_ButtonsAreLargeEnough()
    {
        await Page.SetViewportSizeAsync(375, 667);
        await Page.GotoAsync($"{BaseUrl}/Auth/Login");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        var submitButton = Page.Locator("button[type='submit']");
        await Expect(submitButton).ToBeVisibleAsync();

        var buttonBox = await submitButton.BoundingBoxAsync();
        Assert.That(buttonBox, Is.Not.Null);
        Assert.That(buttonBox!.Height, Is.GreaterThanOrEqualTo(40));
    }

    [Test]
    public async Task Tablet_Landscape_LayoutAdapts()
    {
        await Page.SetViewportSizeAsync(1024, 768);
        await RegisterNewUser();

        await Expect(Page.Locator(".page-title")).ToBeVisibleAsync();
        await Expect(Page.Locator(".tab-bar")).ToBeVisibleAsync();
    }

    private static IEnumerable<(int Width, int Height, string Name)> GetMobileViewports()
    {
        return MobileViewports;
    }
}
