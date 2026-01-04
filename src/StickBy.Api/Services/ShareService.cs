using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using QRCoder;
using StickBy.Infrastructure.Data;
using StickBy.Infrastructure.Entities;
using StickBy.Shared.Models.Contacts;
using StickBy.Shared.Models.Shares;

namespace StickBy.Api.Services;

public interface IShareService
{
    Task<List<ShareDto>> GetSharesAsync(Guid userId);
    Task<ShareDto?> GetShareAsync(Guid userId, Guid shareId);
    Task<ShareDto> CreateShareAsync(Guid userId, CreateShareRequest request);
    Task<bool> DeleteShareAsync(Guid userId, Guid shareId);
    Task<ShareViewDto?> GetShareByTokenAsync(string token);
    Task<byte[]?> GenerateQrCodeAsync(Guid userId, Guid shareId, string baseUrl);
}

public class ShareService : IShareService
{
    private readonly StickByDbContext _context;
    private readonly IEncryptionService _encryptionService;

    public ShareService(StickByDbContext context, IEncryptionService encryptionService)
    {
        _context = context;
        _encryptionService = encryptionService;
    }

    public async Task<List<ShareDto>> GetSharesAsync(Guid userId)
    {
        var shares = await _context.Shares
            .Where(s => s.UserId == userId)
            .Include(s => s.ShareContacts)
            .OrderByDescending(s => s.CreatedAt)
            .ToListAsync();

        return shares.Select(MapToDto).ToList();
    }

    public async Task<ShareDto?> GetShareAsync(Guid userId, Guid shareId)
    {
        var share = await _context.Shares
            .Include(s => s.ShareContacts)
            .FirstOrDefaultAsync(s => s.Id == shareId && s.UserId == userId);

        return share == null ? null : MapToDto(share);
    }

    public async Task<ShareDto> CreateShareAsync(Guid userId, CreateShareRequest request)
    {
        // Verify all contacts belong to user
        var validContactIds = await _context.ContactInfos
            .Where(c => c.UserId == userId && request.ContactIds.Contains(c.Id))
            .Select(c => c.Id)
            .ToListAsync();

        if (validContactIds.Count != request.ContactIds.Count)
            throw new InvalidOperationException("Invalid contact IDs");

        var share = new Share
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Token = GenerateShareToken(),
            Name = request.Name,
            ExpiresAt = request.ExpiresAt
        };

        share.ShareContacts = validContactIds.Select(cid => new ShareContact
        {
            ShareId = share.Id,
            ContactInfoId = cid
        }).ToList();

        _context.Shares.Add(share);
        await _context.SaveChangesAsync();

        return MapToDto(share);
    }

    public async Task<bool> DeleteShareAsync(Guid userId, Guid shareId)
    {
        var share = await _context.Shares
            .FirstOrDefaultAsync(s => s.Id == shareId && s.UserId == userId);

        if (share == null)
            return false;

        _context.Shares.Remove(share);
        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<ShareViewDto?> GetShareByTokenAsync(string token)
    {
        var share = await _context.Shares
            .Include(s => s.User)
            .Include(s => s.ShareContacts)
                .ThenInclude(sc => sc.ContactInfo)
            .FirstOrDefaultAsync(s => s.Token == token);

        if (share == null)
            return null;

        // Check expiry
        if (share.ExpiresAt.HasValue && share.ExpiresAt < DateTime.UtcNow)
            return null;

        // Increment view count
        share.ViewCount++;
        await _context.SaveChangesAsync();

        var contacts = share.ShareContacts
            .Select(sc => new ContactDto
            {
                Id = sc.ContactInfo.Id,
                Type = sc.ContactInfo.Type,
                Label = sc.ContactInfo.Label,
                Value = _encryptionService.Decrypt(sc.ContactInfo.EncryptedValue, share.UserId),
                SortOrder = sc.ContactInfo.SortOrder
            })
            .OrderBy(c => c.SortOrder)
            .ToList();

        return new ShareViewDto
        {
            OwnerDisplayName = share.User.DisplayName,
            Contacts = contacts
        };
    }

    public async Task<byte[]?> GenerateQrCodeAsync(Guid userId, Guid shareId, string baseUrl)
    {
        var share = await _context.Shares
            .FirstOrDefaultAsync(s => s.Id == shareId && s.UserId == userId);

        if (share == null)
            return null;

        var url = $"{baseUrl.TrimEnd('/')}/s/{share.Token}";

        using var qrGenerator = new QRCodeGenerator();
        using var qrCodeData = qrGenerator.CreateQrCode(url, QRCodeGenerator.ECCLevel.Q);
        using var qrCode = new PngByteQRCode(qrCodeData);

        return qrCode.GetGraphic(10);
    }

    private static ShareDto MapToDto(Share share)
    {
        return new ShareDto
        {
            Id = share.Id,
            Token = share.Token,
            Name = share.Name,
            ExpiresAt = share.ExpiresAt,
            ViewCount = share.ViewCount,
            CreatedAt = share.CreatedAt,
            ContactIds = share.ShareContacts.Select(sc => sc.ContactInfoId).ToList()
        };
    }

    private static string GenerateShareToken()
    {
        var bytes = new byte[24];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(bytes);
        return Convert.ToBase64String(bytes)
            .Replace("+", "-")
            .Replace("/", "_")
            .TrimEnd('=');
    }
}
