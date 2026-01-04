using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StickBy.Api.Services;
using StickBy.Shared.Enums;
using StickBy.Shared.Models.Groups;

namespace StickBy.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class GroupsController : ControllerBase
{
    private readonly IGroupService _groupService;

    public GroupsController(IGroupService groupService)
    {
        _groupService = groupService;
    }

    [HttpGet]
    public async Task<ActionResult<List<GroupDto>>> GetGroups()
    {
        var userId = GetUserId();
        var groups = await _groupService.GetGroupsAsync(userId);
        return Ok(groups);
    }

    [HttpGet("invitations")]
    public async Task<ActionResult<List<GroupDto>>> GetPendingInvitations()
    {
        var userId = GetUserId();
        var invitations = await _groupService.GetPendingInvitationsAsync(userId);
        return Ok(invitations);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<GroupDetailDto>> GetGroup(Guid id)
    {
        var userId = GetUserId();
        var group = await _groupService.GetGroupDetailAsync(userId, id);

        if (group == null)
            return NotFound();

        return Ok(group);
    }

    [HttpPost]
    public async Task<ActionResult<GroupDto>> CreateGroup([FromBody] CreateGroupRequest request)
    {
        var userId = GetUserId();
        var group = await _groupService.CreateGroupAsync(userId, request);
        return CreatedAtAction(nameof(GetGroup), new { id = group.Id }, group);
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<GroupDto>> UpdateGroup(Guid id, [FromBody] UpdateGroupRequest request)
    {
        var userId = GetUserId();
        var group = await _groupService.UpdateGroupAsync(userId, id, request);

        if (group == null)
            return NotFound();

        return Ok(group);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteGroup(Guid id)
    {
        var userId = GetUserId();
        var deleted = await _groupService.DeleteGroupAsync(userId, id);

        if (!deleted)
            return NotFound();

        return NoContent();
    }

    [HttpPost("{id:guid}/invite")]
    public async Task<IActionResult> InviteToGroup(Guid id, [FromBody] InviteToGroupRequest request)
    {
        var userId = GetUserId();
        var success = await _groupService.InviteToGroupAsync(userId, id, request);

        if (!success)
            return BadRequest(new { message = "Einladung fehlgeschlagen. Benutzer existiert nicht oder ist bereits Mitglied." });

        return Ok(new { message = "Einladung gesendet" });
    }

    [HttpPost("{id:guid}/join")]
    public async Task<IActionResult> JoinGroup(Guid id)
    {
        var userId = GetUserId();
        var success = await _groupService.JoinGroupAsync(userId, id);

        if (!success)
            return BadRequest(new { message = "Beitreten fehlgeschlagen" });

        return Ok(new { message = "Erfolgreich beigetreten" });
    }

    [HttpPost("{id:guid}/decline")]
    public async Task<IActionResult> DeclineInvitation(Guid id)
    {
        var userId = GetUserId();
        var success = await _groupService.DeclineInvitationAsync(userId, id);

        if (!success)
            return BadRequest(new { message = "Ablehnen fehlgeschlagen" });

        return Ok(new { message = "Einladung abgelehnt" });
    }

    [HttpPost("{id:guid}/leave")]
    public async Task<IActionResult> LeaveGroup(Guid id)
    {
        var userId = GetUserId();
        var success = await _groupService.LeaveGroupAsync(userId, id);

        if (!success)
            return BadRequest(new { message = "Verlassen fehlgeschlagen. Gruppenersteller kann die Gruppe nicht verlassen." });

        return Ok(new { message = "Gruppe verlassen" });
    }

    [HttpDelete("{id:guid}/members/{memberId:guid}")]
    public async Task<IActionResult> RemoveMember(Guid id, Guid memberId)
    {
        var userId = GetUserId();
        var success = await _groupService.RemoveMemberAsync(userId, id, memberId);

        if (!success)
            return BadRequest(new { message = "Entfernen fehlgeschlagen" });

        return NoContent();
    }

    [HttpPut("{id:guid}/members/{memberId:guid}/role")]
    public async Task<IActionResult> UpdateMemberRole(Guid id, Guid memberId, [FromBody] UpdateMemberRoleRequest request)
    {
        var userId = GetUserId();
        var success = await _groupService.UpdateMemberRoleAsync(userId, id, memberId, request.Role);

        if (!success)
            return BadRequest(new { message = "Rolle aendern fehlgeschlagen" });

        return Ok(new { message = "Rolle geaendert" });
    }

    [HttpGet("{id:guid}/shares")]
    public async Task<ActionResult<List<GroupShareDto>>> GetGroupShares(Guid id)
    {
        var userId = GetUserId();
        var shares = await _groupService.GetGroupSharesAsync(userId, id);
        return Ok(shares);
    }

    [HttpPost("{id:guid}/shares")]
    public async Task<ActionResult<GroupShareDto>> ShareToGroup(Guid id, [FromBody] ShareToGroupRequest request)
    {
        var userId = GetUserId();
        var share = await _groupService.ShareToGroupAsync(userId, id, request);

        if (share == null)
            return BadRequest(new { message = "Teilen fehlgeschlagen" });

        return CreatedAtAction(nameof(GetGroupShares), new { id = id }, share);
    }

    [HttpDelete("{id:guid}/shares/{shareId:guid}")]
    public async Task<IActionResult> DeleteGroupShare(Guid id, Guid shareId)
    {
        var userId = GetUserId();
        var success = await _groupService.DeleteGroupShareAsync(userId, id, shareId);

        if (!success)
            return NotFound();

        return NoContent();
    }

    private Guid GetUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.Parse(userIdClaim!);
    }
}

public class UpdateMemberRoleRequest
{
    public GroupMemberRole Role { get; set; }
}
