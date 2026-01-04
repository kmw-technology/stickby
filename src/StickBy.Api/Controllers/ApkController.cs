using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StickBy.Api.Services;
using StickBy.Shared.Models.Apks;

namespace StickBy.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ApkController : ControllerBase
{
    private readonly IApkService _apkService;
    private readonly IConfiguration _configuration;

    // Admin emails - can be configured via appsettings.json
    private readonly HashSet<string> _adminEmails;

    public ApkController(IApkService apkService, IConfiguration configuration)
    {
        _apkService = apkService;
        _configuration = configuration;

        // Load admin emails from configuration, with a default fallback
        var adminEmailsConfig = _configuration.GetSection("AdminEmails").Get<string[]>();
        _adminEmails = new HashSet<string>(
            adminEmailsConfig ?? new[] { "admin@stickby.de", "jonas@kmw-technology.de" },
            StringComparer.OrdinalIgnoreCase
        );
    }

    [HttpGet]
    public async Task<ActionResult<List<ApkReleaseDto>>> GetAllReleases()
    {
        if (!IsAdmin())
            return Forbid();

        var releases = await _apkService.GetAllReleasesAsync();
        return Ok(releases);
    }

    [HttpGet("latest")]
    public async Task<ActionResult<ApkReleaseDto>> GetLatestRelease()
    {
        if (!IsAdmin())
            return Forbid();

        var release = await _apkService.GetLatestReleaseAsync();
        if (release == null)
            return NotFound(new { message = "No APK releases found" });

        return Ok(release);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ApkReleaseDto>> GetRelease(Guid id)
    {
        if (!IsAdmin())
            return Forbid();

        var release = await _apkService.GetReleaseAsync(id);
        if (release == null)
            return NotFound();

        return Ok(release);
    }

    [HttpGet("{id:guid}/download")]
    public async Task<IActionResult> DownloadApk(Guid id)
    {
        if (!IsAdmin())
            return Forbid();

        var release = await _apkService.GetReleaseAsync(id);
        if (release == null)
            return NotFound();

        var fileData = await _apkService.GetApkFileAsync(id);
        if (fileData == null)
            return NotFound();

        return File(fileData, "application/vnd.android.package-archive", release.FileName);
    }

    [HttpPost("upload")]
    [RequestSizeLimit(200_000_000)] // 200 MB limit for APK files
    public async Task<ActionResult<ApkReleaseDto>> UploadApk([FromForm] IFormFile file, [FromForm] string version, [FromForm] string? releaseNotes)
    {
        if (!IsAdmin())
            return Forbid();

        if (file == null || file.Length == 0)
            return BadRequest(new { message = "No file uploaded" });

        if (!file.FileName.EndsWith(".apk", StringComparison.OrdinalIgnoreCase))
            return BadRequest(new { message = "File must be an APK file" });

        if (string.IsNullOrWhiteSpace(version))
            return BadRequest(new { message = "Version is required" });

        using var memoryStream = new MemoryStream();
        await file.CopyToAsync(memoryStream);
        var fileData = memoryStream.ToArray();

        var userId = GetUserId();
        var release = await _apkService.UploadApkAsync(version, file.FileName, fileData, releaseNotes, userId);

        return CreatedAtAction(nameof(GetRelease), new { id = release.Id }, release);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteApk(Guid id)
    {
        if (!IsAdmin())
            return Forbid();

        var deleted = await _apkService.DeleteApkAsync(id);
        if (!deleted)
            return NotFound();

        return NoContent();
    }

    [HttpPost("{id:guid}/set-latest")]
    public async Task<IActionResult> SetAsLatest(Guid id)
    {
        if (!IsAdmin())
            return Forbid();

        var success = await _apkService.SetAsLatestAsync(id);
        if (!success)
            return NotFound();

        return NoContent();
    }

    private bool IsAdmin()
    {
        var email = User.FindFirst(ClaimTypes.Email)?.Value;
        return email != null && _adminEmails.Contains(email);
    }

    private Guid GetUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.Parse(userIdClaim!);
    }
}
