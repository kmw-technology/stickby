using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using StickBy.Infrastructure.Data;
using StickBy.Infrastructure.Entities;
using StickBy.Shared.Enums;
using StickBy.Shared.Models.Contacts;
using StickBy.Shared.Models.Profile;

namespace StickBy.Api.Services;

public interface IProfileService
{
    Task<ProfileDto?> GetProfileAsync(Guid userId);
    Task<ProfileDto?> UpdateProfileAsync(Guid userId, UpdateProfileRequest request);
    Task<bool> UpdateProfileImageAsync(Guid userId, string imageUrl);
    Task<bool> UpdateContactReleaseGroupsAsync(Guid userId, Guid contactId, ReleaseGroup releaseGroups);
    Task<bool> BulkUpdateReleaseGroupsAsync(Guid userId, BulkUpdateReleaseGroupsRequest request);
}

public class ProfileService : IProfileService
{
    private readonly StickByDbContext _context;
    private readonly UserManager<User> _userManager;
    private readonly IEncryptionService _encryptionService;

    public ProfileService(
        StickByDbContext context,
        UserManager<User> userManager,
        IEncryptionService encryptionService)
    {
        _context = context;
        _userManager = userManager;
        _encryptionService = encryptionService;
    }

    public async Task<ProfileDto?> GetProfileAsync(Guid userId)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user == null) return null;

        var contacts = await _context.ContactInfos
            .Where(c => c.UserId == userId)
            .OrderBy(c => c.SortOrder)
            .ToListAsync();

        var contactsByCategory = GroupContactsByCategory(contacts, userId);

        return new ProfileDto
        {
            Id = user.Id,
            DisplayName = user.DisplayName,
            Email = user.Email ?? string.Empty,
            ProfileImageUrl = user.ProfileImageUrl,
            Bio = user.Bio,
            ContactsByCategory = contactsByCategory
        };
    }

    public async Task<ProfileDto?> UpdateProfileAsync(Guid userId, UpdateProfileRequest request)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user == null) return null;

        user.DisplayName = request.DisplayName;
        user.Bio = request.Bio;

        await _userManager.UpdateAsync(user);

        return await GetProfileAsync(userId);
    }

    public async Task<bool> UpdateProfileImageAsync(Guid userId, string imageUrl)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user == null) return false;

        user.ProfileImageUrl = imageUrl;
        await _userManager.UpdateAsync(user);

        return true;
    }

    public async Task<bool> UpdateContactReleaseGroupsAsync(Guid userId, Guid contactId, ReleaseGroup releaseGroups)
    {
        var contact = await _context.ContactInfos
            .FirstOrDefaultAsync(c => c.Id == contactId && c.UserId == userId);

        if (contact == null) return false;

        contact.ReleaseGroups = releaseGroups;
        contact.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> BulkUpdateReleaseGroupsAsync(Guid userId, BulkUpdateReleaseGroupsRequest request)
    {
        var contactIds = request.Updates.Select(u => u.ContactId).ToList();
        var contacts = await _context.ContactInfos
            .Where(c => c.UserId == userId && contactIds.Contains(c.Id))
            .ToListAsync();

        foreach (var update in request.Updates)
        {
            var contact = contacts.FirstOrDefault(c => c.Id == update.ContactId);
            if (contact != null)
            {
                contact.ReleaseGroups = update.ReleaseGroups;
                contact.UpdatedAt = DateTime.UtcNow;
            }
        }

        await _context.SaveChangesAsync();
        return true;
    }

    private Dictionary<string, List<ContactDto>> GroupContactsByCategory(List<ContactInfo> contacts, Guid userId)
    {
        var result = new Dictionary<string, List<ContactDto>>
        {
            ["personal"] = new(),
            ["private"] = new(),
            ["business"] = new(),
            ["social"] = new(),
            ["gaming"] = new(),
            ["general"] = new()
        };

        foreach (var contact in contacts)
        {
            var dto = MapToDto(contact, userId);
            var category = GetCategoryForType(contact.Type);
            result[category].Add(dto);
        }

        return result;
    }

    private static string GetCategoryForType(ContactType type)
    {
        var typeValue = (int)type;
        return typeValue switch
        {
            >= 100 and < 200 => "personal",
            >= 200 and < 300 => "private",
            >= 300 and < 400 => "business",
            >= 400 and < 500 => "social",
            >= 500 and < 600 => "gaming",
            _ => "general"
        };
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
