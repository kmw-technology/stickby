using Microsoft.EntityFrameworkCore;
using StickBy.Infrastructure.Data;
using StickBy.Infrastructure.Entities;
using StickBy.Shared.Models.Contacts;

namespace StickBy.Api.Services;

public interface IContactService
{
    Task<List<ContactDto>> GetContactsAsync(Guid userId);
    Task<ContactDto?> GetContactAsync(Guid userId, Guid contactId);
    Task<ContactDto> CreateContactAsync(Guid userId, CreateContactRequest request);
    Task<ContactDto?> UpdateContactAsync(Guid userId, Guid contactId, UpdateContactRequest request);
    Task<bool> DeleteContactAsync(Guid userId, Guid contactId);
}

public class ContactService : IContactService
{
    private readonly StickByDbContext _context;
    private readonly IEncryptionService _encryptionService;

    public ContactService(StickByDbContext context, IEncryptionService encryptionService)
    {
        _context = context;
        _encryptionService = encryptionService;
    }

    public async Task<List<ContactDto>> GetContactsAsync(Guid userId)
    {
        var contacts = await _context.ContactInfos
            .Where(c => c.UserId == userId)
            .OrderBy(c => c.SortOrder)
            .ToListAsync();

        return contacts.Select(c => MapToDto(c, userId)).ToList();
    }

    public async Task<ContactDto?> GetContactAsync(Guid userId, Guid contactId)
    {
        var contact = await _context.ContactInfos
            .FirstOrDefaultAsync(c => c.Id == contactId && c.UserId == userId);

        return contact == null ? null : MapToDto(contact, userId);
    }

    public async Task<ContactDto> CreateContactAsync(Guid userId, CreateContactRequest request)
    {
        var contact = new ContactInfo
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Type = request.Type,
            Label = request.Label,
            EncryptedValue = _encryptionService.Encrypt(request.Value, userId),
            SortOrder = request.SortOrder,
            ReleaseGroups = request.ReleaseGroups
        };

        _context.ContactInfos.Add(contact);
        await _context.SaveChangesAsync();

        return MapToDto(contact, userId);
    }

    public async Task<ContactDto?> UpdateContactAsync(Guid userId, Guid contactId, UpdateContactRequest request)
    {
        var contact = await _context.ContactInfos
            .FirstOrDefaultAsync(c => c.Id == contactId && c.UserId == userId);

        if (contact == null)
            return null;

        contact.Type = request.Type;
        contact.Label = request.Label;
        contact.EncryptedValue = _encryptionService.Encrypt(request.Value, userId);
        contact.SortOrder = request.SortOrder;
        contact.ReleaseGroups = request.ReleaseGroups;
        contact.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return MapToDto(contact, userId);
    }

    public async Task<bool> DeleteContactAsync(Guid userId, Guid contactId)
    {
        var contact = await _context.ContactInfos
            .FirstOrDefaultAsync(c => c.Id == contactId && c.UserId == userId);

        if (contact == null)
            return false;

        _context.ContactInfos.Remove(contact);
        await _context.SaveChangesAsync();

        return true;
    }

    private ContactDto MapToDto(ContactInfo contact, Guid userId)
    {
        return new ContactDto
        {
            Id = contact.Id,
            Type = contact.Type,
            Label = contact.Label,
            Value = _encryptionService.Decrypt(contact.EncryptedValue, userId),
            SortOrder = contact.SortOrder,
            ReleaseGroups = contact.ReleaseGroups
        };
    }
}
