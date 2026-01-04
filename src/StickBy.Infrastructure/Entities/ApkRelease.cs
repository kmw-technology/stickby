namespace StickBy.Infrastructure.Entities;

public class ApkRelease
{
    public Guid Id { get; set; }
    public string Version { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
    public byte[] FileData { get; set; } = Array.Empty<byte>();
    public long FileSizeBytes { get; set; }
    public string? ReleaseNotes { get; set; }
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    public Guid? UploadedByUserId { get; set; }
    public bool IsLatest { get; set; }

    // Navigation properties
    public virtual User? UploadedBy { get; set; }
}
