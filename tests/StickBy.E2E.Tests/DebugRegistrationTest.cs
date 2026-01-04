namespace StickBy.E2E.Tests;

[TestFixture]
public class DebugRegistrationTest : PageTest
{
    private const string BaseUrl = "https://www.kmw-technology.de/stickby/website";

    [Test]
    public async Task Debug_Registration_ShowsActualBehavior()
    {
        var email = $"debug-{Guid.NewGuid():N}@example.com";

        await Page.GotoAsync($"{BaseUrl}/Auth/Register");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);

        Console.WriteLine($"=== Starting URL: {Page.Url} ===");

        await Page.FillAsync("#DisplayName", "Debug User");
        await Page.FillAsync("#Email", email);
        await Page.FillAsync("#Password", "TestPass123");

        Console.WriteLine("=== Filled form, clicking submit ===");

        await Page.ClickAsync("button[type='submit']");

        // Wait a bit for any response
        await Page.WaitForTimeoutAsync(5000);

        Console.WriteLine($"=== After submit URL: {Page.Url} ===");

        // Check for error message
        var errorMessage = await Page.Locator(".error-message").IsVisibleAsync();
        if (errorMessage)
        {
            var errorText = await Page.Locator(".error-message").TextContentAsync();
            Console.WriteLine($"=== Error message: {errorText} ===");
        }

        // Get page content
        var pageTitle = await Page.TitleAsync();
        Console.WriteLine($"=== Page title: {pageTitle} ===");

        var h1Text = await Page.Locator("h1").First.TextContentAsync();
        Console.WriteLine($"=== H1 text: {h1Text} ===");

        Assert.Pass("Debug info collected");
    }
}
