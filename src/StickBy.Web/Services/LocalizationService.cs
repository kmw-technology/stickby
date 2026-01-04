using System.Text.Json;

namespace StickBy.Web.Services;

public interface ILocalizationService
{
    string this[string key] { get; }
    string CurrentLanguage { get; }
    void SetLanguage(string language);
}

public class LocalizationService : ILocalizationService
{
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly IWebHostEnvironment _environment;
    private Dictionary<string, string> _translations = new();
    private string _currentLanguage = "de";
    private bool _initialized;

    public LocalizationService(IHttpContextAccessor httpContextAccessor, IWebHostEnvironment environment)
    {
        _httpContextAccessor = httpContextAccessor;
        _environment = environment;
    }

    public string this[string key]
    {
        get
        {
            EnsureInitialized();
            return _translations.TryGetValue(key, out var value) ? value : key;
        }
    }

    public string CurrentLanguage
    {
        get
        {
            EnsureInitialized();
            return _currentLanguage;
        }
    }

    public void SetLanguage(string language)
    {
        if (language != "de" && language != "en")
            language = "de";

        _currentLanguage = language;

        // Store in cookie
        _httpContextAccessor.HttpContext?.Response.Cookies.Append("language", language, new CookieOptions
        {
            Expires = DateTimeOffset.UtcNow.AddYears(1),
            HttpOnly = false,
            Secure = true,
            SameSite = SameSiteMode.Lax
        });

        LoadTranslations();
    }

    private void EnsureInitialized()
    {
        if (_initialized) return;

        // Read language from cookie
        var langCookie = _httpContextAccessor.HttpContext?.Request.Cookies["language"];
        _currentLanguage = langCookie == "en" ? "en" : "de";

        LoadTranslations();
        _initialized = true;
    }

    private void LoadTranslations()
    {
        var path = Path.Combine(_environment.WebRootPath, "locales", $"{_currentLanguage}.json");

        if (File.Exists(path))
        {
            var json = File.ReadAllText(path);
            _translations = JsonSerializer.Deserialize<Dictionary<string, string>>(json) ?? new();
        }
    }
}
