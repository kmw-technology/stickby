using Microsoft.EntityFrameworkCore;
using StickBy.Infrastructure.Data;
using StickBy.Infrastructure.Entities;
using StickBy.Shared.Models.Apks;

namespace StickBy.Api.Services;

public interface IApkService
{
    Task<List<ApkReleaseDto>> GetAllReleasesAsync();
    Task<ApkReleaseDto?> GetLatestReleaseAsync();
    Task<ApkReleaseDto?> GetReleaseAsync(Guid id);
    Task<byte[]?> GetApkFileAsync(Guid id);
    Task<ApkReleaseDto> UploadApkAsync(string version, string fileName, byte[] fileData, string? releaseNotes, Guid uploadedByUserId);
    Task<bool> DeleteApkAsync(Guid id);
    Task<bool> SetAsLatestAsync(Guid id);
}

public class ApkService : IApkService
{
    private readonly StickByDbContext _context;

    public ApkService(StickByDbContext context)
    {
        _context = context;
    }

    public async Task<List<ApkReleaseDto>> GetAllReleasesAsync()
    {
        var releases = await _context.ApkReleases
            .Include(a => a.UploadedBy)
            .OrderByDescending(a => a.UploadedAt)
            .ToListAsync();

        return releases.Select(MapToDto).ToList();
    }

    public async Task<ApkReleaseDto?> GetLatestReleaseAsync()
    {
        var release = await _context.ApkReleases
            .Include(a => a.UploadedBy)
            .Where(a => a.IsLatest)
            .FirstOrDefaultAsync();

        // If no release is marked as latest, get the most recent one
        if (release == null)
        {
            release = await _context.ApkReleases
                .Include(a => a.UploadedBy)
                .OrderByDescending(a => a.UploadedAt)
                .FirstOrDefaultAsync();
        }

        return release == null ? null : MapToDto(release);
    }

    public async Task<ApkReleaseDto?> GetReleaseAsync(Guid id)
    {
        var release = await _context.ApkReleases
            .Include(a => a.UploadedBy)
            .FirstOrDefaultAsync(a => a.Id == id);

        return release == null ? null : MapToDto(release);
    }

    public async Task<byte[]?> GetApkFileAsync(Guid id)
    {
        var release = await _context.ApkReleases.FindAsync(id);
        return release?.FileData;
    }

    public async Task<ApkReleaseDto> UploadApkAsync(string version, string fileName, byte[] fileData, string? releaseNotes, Guid uploadedByUserId)
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
            UploadedByUserId = uploadedByUserId,
            IsLatest = true
        };

        _context.ApkReleases.Add(release);
        await _context.SaveChangesAsync();

        // Reload with navigation property
        await _context.Entry(release).Reference(a => a.UploadedBy).LoadAsync();

        return MapToDto(release);
    }

    public async Task<bool> DeleteApkAsync(Guid id)
    {
        var release = await _context.ApkReleases.FindAsync(id);
        if (release == null)
            return false;

        _context.ApkReleases.Remove(release);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> SetAsLatestAsync(Guid id)
    {
        var release = await _context.ApkReleases.FindAsync(id);
        if (release == null)
            return false;

        // Remove IsLatest from all existing releases
        var existingReleases = await _context.ApkReleases.Where(a => a.IsLatest).ToListAsync();
        foreach (var existing in existingReleases)
        {
            existing.IsLatest = false;
        }

        release.IsLatest = true;
        await _context.SaveChangesAsync();
        return true;
    }

    private static ApkReleaseDto MapToDto(ApkRelease release)
    {
        return new ApkReleaseDto
        {
            Id = release.Id,
            Version = release.Version,
            FileName = release.FileName,
            FileSizeBytes = release.FileSizeBytes,
            ReleaseNotes = release.ReleaseNotes,
            UploadedAt = release.UploadedAt,
            UploadedByEmail = release.UploadedBy?.Email,
            IsLatest = release.IsLatest
        };
    }
}
