using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StickBy.Api.Services;
using StickBy.Shared.Models.Shares;

namespace StickBy.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SharesController : ControllerBase
{
    private readonly IShareService _shareService;

    public SharesController(IShareService shareService)
    {
        _shareService = shareService;
    }

    [Authorize]
    [HttpGet]
    public async Task<ActionResult<List<ShareDto>>> GetShares()
    {
        var userId = GetUserId();
        var shares = await _shareService.GetSharesAsync(userId);
        return Ok(shares);
    }

    [Authorize]
    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ShareDto>> GetShare(Guid id)
    {
        var userId = GetUserId();
        var share = await _shareService.GetShareAsync(userId, id);

        if (share == null)
            return NotFound();

        return Ok(share);
    }

    [Authorize]
    [HttpPost]
    public async Task<ActionResult<ShareDto>> CreateShare([FromBody] CreateShareRequest request)
    {
        var userId = GetUserId();

        try
        {
            var share = await _shareService.CreateShareAsync(userId, request);
            return CreatedAtAction(nameof(GetShare), new { id = share.Id }, share);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize]
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteShare(Guid id)
    {
        var userId = GetUserId();
        var deleted = await _shareService.DeleteShareAsync(userId, id);

        if (!deleted)
            return NotFound();

        return NoContent();
    }

    [HttpGet("view/{token}")]
    [AllowAnonymous]
    public async Task<ActionResult<ShareViewDto>> GetShareByToken(string token)
    {
        var share = await _shareService.GetShareByTokenAsync(token);

        if (share == null)
            return NotFound(new { message = "Share not found or expired" });

        return Ok(share);
    }

    [Authorize]
    [HttpGet("{id:guid}/qr")]
    public async Task<IActionResult> GetQrCode(Guid id)
    {
        var userId = GetUserId();
        var baseUrl = $"{Request.Scheme}://{Request.Host}";
        var qrCode = await _shareService.GenerateQrCodeAsync(userId, id, baseUrl);

        if (qrCode == null)
            return NotFound();

        return File(qrCode, "image/png");
    }

    private Guid GetUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.Parse(userIdClaim!);
    }
}
