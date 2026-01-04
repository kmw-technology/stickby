using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StickBy.Api.Services;
using StickBy.Shared.Enums;
using StickBy.Shared.Models.Profile;

namespace StickBy.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ProfileController : ControllerBase
{
    private readonly IProfileService _profileService;

    public ProfileController(IProfileService profileService)
    {
        _profileService = profileService;
    }

    private Guid GetUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.Parse(userIdClaim!);
    }

    [HttpGet]
    public async Task<ActionResult<ProfileDto>> GetProfile()
    {
        var userId = GetUserId();
        var profile = await _profileService.GetProfileAsync(userId);

        if (profile == null)
            return NotFound();

        return Ok(profile);
    }

    [HttpPut]
    public async Task<ActionResult<ProfileDto>> UpdateProfile([FromBody] UpdateProfileRequest request)
    {
        var userId = GetUserId();
        var profile = await _profileService.UpdateProfileAsync(userId, request);

        if (profile == null)
            return NotFound();

        return Ok(profile);
    }

    [HttpPut("image")]
    public async Task<IActionResult> UpdateProfileImage([FromBody] UpdateProfileImageRequest request)
    {
        var userId = GetUserId();
        var success = await _profileService.UpdateProfileImageAsync(userId, request.ImageUrl);

        if (!success)
            return NotFound();

        return NoContent();
    }

    [HttpPut("contacts/{contactId}/release-groups")]
    public async Task<IActionResult> UpdateContactReleaseGroups(Guid contactId, [FromBody] UpdateReleaseGroupRequest request)
    {
        var userId = GetUserId();
        var success = await _profileService.UpdateContactReleaseGroupsAsync(userId, contactId, request.ReleaseGroups);

        if (!success)
            return NotFound();

        return NoContent();
    }

    [HttpPut("release-groups/bulk")]
    public async Task<IActionResult> BulkUpdateReleaseGroups([FromBody] BulkUpdateReleaseGroupsRequest request)
    {
        var userId = GetUserId();
        await _profileService.BulkUpdateReleaseGroupsAsync(userId, request);
        return NoContent();
    }
}

public class UpdateProfileImageRequest
{
    public string ImageUrl { get; set; } = string.Empty;
}

public class UpdateReleaseGroupRequest
{
    public ReleaseGroup ReleaseGroups { get; set; }
}
