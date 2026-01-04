using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StickBy.Api.Services;
using StickBy.Shared.Models.Contacts;

namespace StickBy.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ContactsController : ControllerBase
{
    private readonly IContactService _contactService;

    public ContactsController(IContactService contactService)
    {
        _contactService = contactService;
    }

    [HttpGet]
    public async Task<ActionResult<List<ContactDto>>> GetContacts()
    {
        var userId = GetUserId();
        var contacts = await _contactService.GetContactsAsync(userId);
        return Ok(contacts);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ContactDto>> GetContact(Guid id)
    {
        var userId = GetUserId();
        var contact = await _contactService.GetContactAsync(userId, id);

        if (contact == null)
            return NotFound();

        return Ok(contact);
    }

    [HttpPost]
    public async Task<ActionResult<ContactDto>> CreateContact([FromBody] CreateContactRequest request)
    {
        var userId = GetUserId();
        var contact = await _contactService.CreateContactAsync(userId, request);
        return CreatedAtAction(nameof(GetContact), new { id = contact.Id }, contact);
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<ContactDto>> UpdateContact(Guid id, [FromBody] UpdateContactRequest request)
    {
        var userId = GetUserId();
        var contact = await _contactService.UpdateContactAsync(userId, id, request);

        if (contact == null)
            return NotFound();

        return Ok(contact);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteContact(Guid id)
    {
        var userId = GetUserId();
        var deleted = await _contactService.DeleteContactAsync(userId, id);

        if (!deleted)
            return NotFound();

        return NoContent();
    }

    private Guid GetUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.Parse(userIdClaim!);
    }
}
