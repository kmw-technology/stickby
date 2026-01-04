namespace StickBy.Shared.Models.Apks;

public class ApkReleaseDto
{
    public Guid Id { get; set; }
    public string Version { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
    public long FileSizeBytes { get; set; }
    public string? ReleaseNotes { get; set; }
    public DateTime UploadedAt { get; set; }
    public string? UploadedByEmail { get; set; }
    public bool IsLatest { get; set; }
}
