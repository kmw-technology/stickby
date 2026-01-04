using Microsoft.EntityFrameworkCore;
using StickBy.Infrastructure.Data;
using StickBy.Infrastructure.Entities;

namespace StickBy.Admin.Web.Services;

public interface IAdminService
{
    Task<DashboardStats> GetDashboardStatsAsync();
    Task<List<UserSummary>> GetUsersAsync(string? search = null, int page = 1, int pageSize = 20);
    Task<int> GetUserCountAsync(string? search = null);
    Task<UserDetail?> GetUserDetailAsync(Guid userId);
    Task<bool> ToggleUserActiveAsync(Guid userId);
    Task<List<ShareSummary>> GetSharesAsync(int page = 1, int pageSize = 20);
    Task<int> GetShareCountAsync();
    Task<List<AuditLogEntry>> GetAuditLogsAsync(int page = 1, int pageSize = 50);
    Task<int> GetAuditLogCountAsync();

    // APK Management
    Task<List<ApkSummary>> GetApkReleasesAsync();
    Task<ApkSummary> UploadApkAsync(string version, string fileName, byte[] fileData, string? releaseNotes);
    Task<byte[]?> GetApkFileAsync(Guid id);
    Task<string?> GetApkDownloadUrlAsync(Guid id);
    Task<bool> DeleteApkAsync(Guid id);
    Task<bool> SetApkAsLatestAsync(Guid id);
}

public class AdminService : IAdminService
{
    private readonly StickByDbContext _context;

    public AdminService(StickByDbContext context)
    {
        _context = context;
    }

    public async Task<DashboardStats> GetDashboardStatsAsync()
    {
        var now = DateTime.UtcNow;
        var last24Hours = now.AddHours(-24);
        var last7Days = now.AddDays(-7);

        return new DashboardStats
        {
            TotalUsers = await _context.Users.CountAsync(),
            ActiveUsers = await _context.Users.CountAsync(u => u.IsActive),
            TotalContacts = await _context.ContactInfos.CountAsync(),
            TotalShares = await _context.Shares.CountAsync(),
            TotalShareViews = await _context.Shares.SumAsync(s => s.ViewCount),
            NewUsersLast24Hours = await _context.Users.CountAsync(u => u.CreatedAt >= last24Hours),
            NewUsersLast7Days = await _context.Users.CountAsync(u => u.CreatedAt >= last7Days),
            SharesCreatedLast7Days = await _context.Shares.CountAsync(s => s.CreatedAt >= last7Days),
            RecentAuditLogs = await _context.AuditLogs
                .OrderByDescending(a => a.Timestamp)
                .Take(10)
                .Select(a => new AuditLogEntry
                {
                    Id = a.Id,
                    Action = a.Action,
                    EntityType = a.EntityType,
                    EntityId = a.EntityId,
                    UserEmail = a.User != null ? a.User.Email : null,
                    IpAddress = a.IpAddress,
                    Timestamp = a.Timestamp
                })
                .ToListAsync()
        };
    }

    public async Task<List<UserSummary>> GetUsersAsync(string? search = null, int page = 1, int pageSize = 20)
    {
        var query = _context.Users.AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            search = search.ToLower();
            query = query.Where(u =>
                u.Email!.ToLower().Contains(search) ||
                u.DisplayName.ToLower().Contains(search));
        }

        return await query
            .OrderByDescending(u => u.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new UserSummary
            {
                Id = u.Id,
                Email = u.Email!,
                DisplayName = u.DisplayName,
                IsActive = u.IsActive,
                CreatedAt = u.CreatedAt,
                LastLoginAt = u.LastLoginAt,
                ContactCount = u.Contacts.Count,
                ShareCount = u.Shares.Count
            })
            .ToListAsync();
    }

    public async Task<int> GetUserCountAsync(string? search = null)
    {
        var query = _context.Users.AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            search = search.ToLower();
            query = query.Where(u =>
                u.Email!.ToLower().Contains(search) ||
                u.DisplayName.ToLower().Contains(search));
        }

        return await query.CountAsync();
    }

    public async Task<UserDetail?> GetUserDetailAsync(Guid userId)
    {
        var user = await _context.Users
            .Include(u => u.Contacts)
            .Include(u => u.Shares)
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null) return null;

        return new UserDetail
        {
            Id = user.Id,
            Email = user.Email!,
            DisplayName = user.DisplayName,
            IsActive = user.IsActive,
            EmailConfirmed = user.EmailConfirmed,
            CreatedAt = user.CreatedAt,
            LastLoginAt = user.LastLoginAt,
            Contacts = user.Contacts.Select(c => new ContactSummary
            {
                Id = c.Id,
                Type = c.Type.ToString(),
                Label = c.Label,
                CreatedAt = c.CreatedAt
            }).ToList(),
            Shares = user.Shares.Select(s => new ShareSummary
            {
                Id = s.Id,
                Name = s.Name,
                Token = s.Token,
                ViewCount = s.ViewCount,
                CreatedAt = s.CreatedAt,
                ExpiresAt = s.ExpiresAt,
                UserEmail = user.Email
            }).ToList()
        };
    }

    public async Task<bool> ToggleUserActiveAsync(Guid userId)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return false;

        user.IsActive = !user.IsActive;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<List<ShareSummary>> GetSharesAsync(int page = 1, int pageSize = 20)
    {
        return await _context.Shares
            .Include(s => s.User)
            .OrderByDescending(s => s.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(s => new ShareSummary
            {
                Id = s.Id,
                Name = s.Name,
                Token = s.Token,
                ViewCount = s.ViewCount,
                CreatedAt = s.CreatedAt,
                ExpiresAt = s.ExpiresAt,
                UserEmail = s.User != null ? s.User.Email : null
            })
            .ToListAsync();
    }

    public async Task<int> GetShareCountAsync()
    {
        return await _context.Shares.CountAsync();
    }

    public async Task<List<AuditLogEntry>> GetAuditLogsAsync(int page = 1, int pageSize = 50)
    {
        return await _context.AuditLogs
            .Include(a => a.User)
            .OrderByDescending(a => a.Timestamp)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(a => new AuditLogEntry
            {
                Id = a.Id,
                Action = a.Action,
                EntityType = a.EntityType,
                EntityId = a.EntityId,
                Details = a.Details,
                UserEmail = a.User != null ? a.User.Email : null,
                IpAddress = a.IpAddress,
                Timestamp = a.Timestamp
            })
            .ToListAsync();
    }

    public async Task<int> GetAuditLogCountAsync()
    {
        return await _context.AuditLogs.CountAsync();
    }

    // APK Management
    public async Task<List<ApkSummary>> GetApkReleasesAsync()
    {
        return await _context.ApkReleases
            .Include(a => a.UploadedBy)
            .OrderByDescending(a => a.UploadedAt)
            .Select(a => new ApkSummary
            {
                Id = a.Id,
                Version = a.Version,
                FileName = a.FileName,
                FileSizeBytes = a.FileSizeBytes,
                ReleaseNotes = a.ReleaseNotes,
                UploadedAt = a.UploadedAt,
                UploadedByEmail = a.UploadedBy != null ? a.UploadedBy.Email : null,
                IsLatest = a.IsLatest
            })
            .ToListAsync();
    }

    public async Task<ApkSummary> UploadApkAsync(string version, string fileName, byte[] fileData, string? releaseNotes)
    {
        // Remove IsLatest from all existing releases
        var existingReleases = await _context.ApkReleases.Where(a => a.IsLatest).ToListAsync();
        foreach (var existing in existingReleases)
        {
            existing.IsLatest = false;
        }

        var release = new ApkRelease
        {
            Id = Guid.NewGuid(),
            Version = version,
            FileName = fileName,
            FileData = fileData,
            FileSizeBytes = fileData.Length,
            ReleaseNotes = releaseNotes,
            UploadedAt = DateTime.UtcNow,
            IsLatest = true
        };

        _context.ApkReleases.Add(release);
        await _context.SaveChangesAsync();

        return new ApkSummary
        {
            Id = release.Id,
            Version = release.Version,
            FileName = release.FileName,
            FileSizeBytes = release.FileSizeBytes,
            ReleaseNotes = release.ReleaseNotes,
            UploadedAt = release.UploadedAt,
            IsLatest = release.IsLatest
        };
    }

    public async Task<byte[]?> GetApkFileAsync(Guid id)
    {
        var release = await _context.ApkReleases.FindAsync(id);
        return release?.FileData;
    }

    public Task<string?> GetApkDownloadUrlAsync(Guid id)
    {
        // Returns local download URL handled by the Admin Panel's download endpoint
        return Task.FromResult<string?>($"~/api/apk-download/{id}");
    }

    public async Task<bool> DeleteApkAsync(Guid id)
    {
        var release = await _context.ApkReleases.FindAsync(id);
        if (release == null) return false;

        _context.ApkReleases.Remove(release);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> SetApkAsLatestAsync(Guid id)
    {
        var release = await _context.ApkReleases.FindAsync(id);
        if (release == null) return false;

        var existingReleases = await _context.ApkReleases.Where(a => a.IsLatest).ToListAsync();
        foreach (var existing in existingReleases)
        {
            existing.IsLatest = false;
        }

        release.IsLatest = true;
        await _context.SaveChangesAsync();
        return true;
    }
}

// DTOs
public class DashboardStats
{
    public int TotalUsers { get; set; }
    public int ActiveUsers { get; set; }
    public int TotalContacts { get; set; }
    public int TotalShares { get; set; }
    public int TotalShareViews { get; set; }
    public int NewUsersLast24Hours { get; set; }
    public int NewUsersLast7Days { get; set; }
    public int SharesCreatedLast7Days { get; set; }
    public List<AuditLogEntry> RecentAuditLogs { get; set; } = new();
}

public class UserSummary
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? LastLoginAt { get; set; }
    public int ContactCount { get; set; }
    public int ShareCount { get; set; }
}

public class UserDetail : UserSummary
{
    public bool EmailConfirmed { get; set; }
    public List<ContactSummary> Contacts { get; set; } = new();
    public List<ShareSummary> Shares { get; set; } = new();
}

public class ContactSummary
{
    public Guid Id { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class ShareSummary
{
    public Guid Id { get; set; }
    public string? Name { get; set; }
    public string Token { get; set; } = string.Empty;
    public int ViewCount { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public string? UserEmail { get; set; }
}

public class AuditLogEntry
{
    public Guid Id { get; set; }
    public string Action { get; set; } = string.Empty;
    public string? EntityType { get; set; }
    public string? EntityId { get; set; }
    public string? Details { get; set; }
    public string? UserEmail { get; set; }
    public string? IpAddress { get; set; }
    public DateTime Timestamp { get; set; }
}

public class ApkSummary
{
    public Guid Id { get; set; }
    public string Version { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
    public long FileSizeBytes { get; set; }
    public string? ReleaseNotes { get; set; }
    public DateTime UploadedAt { get; set; }
    public string? UploadedByEmail { get; set; }
    public bool IsLatest { get; set; }

    public string FileSizeFormatted
    {
        get
        {
            if (FileSizeBytes < 1024)
                return $"{FileSizeBytes} B";
            if (FileSizeBytes < 1024 * 1024)
                return $"{FileSizeBytes / 1024.0:F1} KB";
            return $"{FileSizeBytes / (1024.0 * 1024.0):F1} MB";
        }
    }
}
