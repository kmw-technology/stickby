using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using StickBy.Infrastructure.Entities;

namespace StickBy.Infrastructure.Data;

public class StickByDbContext : IdentityDbContext<User, IdentityRole<Guid>, Guid>
{
    public StickByDbContext(DbContextOptions<StickByDbContext> options) : base(options)
    {
    }

    public DbSet<ContactInfo> ContactInfos => Set<ContactInfo>();
    public DbSet<Share> Shares => Set<Share>();
    public DbSet<ShareContact> ShareContacts => Set<ShareContact>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<MagicLink> MagicLinks => Set<MagicLink>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<Group> Groups => Set<Group>();
    public DbSet<GroupMember> GroupMembers => Set<GroupMember>();
    public DbSet<GroupShare> GroupShares => Set<GroupShare>();
    public DbSet<GroupShareContact> GroupShareContacts => Set<GroupShareContact>();
    public DbSet<Company> Companies => Set<Company>();
    public DbSet<ApkRelease> ApkReleases => Set<ApkRelease>();
    public DbSet<WebSession> WebSessions => Set<WebSession>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // User configuration
        builder.Entity<User>(entity =>
        {
            entity.Property(u => u.DisplayName).HasMaxLength(100);
            entity.Property(u => u.ProfileImageUrl).HasMaxLength(500);
            entity.Property(u => u.Bio).HasMaxLength(500);
            entity.HasIndex(u => u.Email).IsUnique();
        });

        // ContactInfo configuration
        builder.Entity<ContactInfo>(entity =>
        {
            entity.HasKey(c => c.Id);
            entity.Property(c => c.Label).HasMaxLength(50);
            entity.Property(c => c.EncryptedValue).HasMaxLength(1000);

            entity.HasOne(c => c.User)
                .WithMany(u => u.Contacts)
                .HasForeignKey(c => c.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(c => c.UserId);
        });

        // Share configuration
        builder.Entity<Share>(entity =>
        {
            entity.HasKey(s => s.Id);
            entity.Property(s => s.Token).HasMaxLength(64);
            entity.Property(s => s.Name).HasMaxLength(100);

            entity.HasOne(s => s.User)
                .WithMany(u => u.Shares)
                .HasForeignKey(s => s.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(s => s.Token).IsUnique();
            entity.HasIndex(s => s.UserId);
        });

        // ShareContact configuration (many-to-many)
        builder.Entity<ShareContact>(entity =>
        {
            entity.HasKey(sc => new { sc.ShareId, sc.ContactInfoId });

            entity.HasOne(sc => sc.Share)
                .WithMany(s => s.ShareContacts)
                .HasForeignKey(sc => sc.ShareId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(sc => sc.ContactInfo)
                .WithMany(c => c.ShareContacts)
                .HasForeignKey(sc => sc.ContactInfoId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // RefreshToken configuration
        builder.Entity<RefreshToken>(entity =>
        {
            entity.HasKey(rt => rt.Id);
            entity.Property(rt => rt.Token).HasMaxLength(256);
            entity.Property(rt => rt.CreatedByIp).HasMaxLength(50);
            entity.Property(rt => rt.RevokedByIp).HasMaxLength(50);
            entity.Property(rt => rt.ReplacedByToken).HasMaxLength(256);

            entity.HasOne(rt => rt.User)
                .WithMany(u => u.RefreshTokens)
                .HasForeignKey(rt => rt.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(rt => rt.Token);
            entity.HasIndex(rt => rt.UserId);
        });

        // MagicLink configuration
        builder.Entity<MagicLink>(entity =>
        {
            entity.HasKey(ml => ml.Id);
            entity.Property(ml => ml.Token).HasMaxLength(256);

            entity.HasOne(ml => ml.User)
                .WithMany(u => u.MagicLinks)
                .HasForeignKey(ml => ml.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(ml => ml.Token);
        });

        // AuditLog configuration
        builder.Entity<AuditLog>(entity =>
        {
            entity.HasKey(al => al.Id);
            entity.Property(al => al.Action).HasMaxLength(100);
            entity.Property(al => al.EntityType).HasMaxLength(100);
            entity.Property(al => al.EntityId).HasMaxLength(50);
            entity.Property(al => al.IpAddress).HasMaxLength(50);
            entity.Property(al => al.UserAgent).HasMaxLength(500);

            entity.HasOne(al => al.User)
                .WithMany()
                .HasForeignKey(al => al.UserId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasIndex(al => al.UserId);
            entity.HasIndex(al => al.Timestamp);
        });

        // Group configuration
        builder.Entity<Group>(entity =>
        {
            entity.HasKey(g => g.Id);
            entity.Property(g => g.Name).HasMaxLength(100).IsRequired();
            entity.Property(g => g.Description).HasMaxLength(500);
            entity.Property(g => g.CoverImageUrl).HasMaxLength(500);

            entity.HasOne(g => g.CreatedByUser)
                .WithMany(u => u.CreatedGroups)
                .HasForeignKey(g => g.CreatedByUserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(g => g.CreatedByUserId);
        });

        // GroupMember configuration (composite key)
        builder.Entity<GroupMember>(entity =>
        {
            entity.HasKey(gm => new { gm.GroupId, gm.UserId });

            entity.HasOne(gm => gm.Group)
                .WithMany(g => g.Members)
                .HasForeignKey(gm => gm.GroupId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(gm => gm.User)
                .WithMany(u => u.GroupMemberships)
                .HasForeignKey(gm => gm.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(gm => gm.UserId);
            entity.HasIndex(gm => gm.Status);
        });

        // GroupShare configuration
        builder.Entity<GroupShare>(entity =>
        {
            entity.HasKey(gs => gs.Id);
            entity.Property(gs => gs.Message).HasMaxLength(500);

            entity.HasOne(gs => gs.Group)
                .WithMany(g => g.GroupShares)
                .HasForeignKey(gs => gs.GroupId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(gs => gs.User)
                .WithMany(u => u.GroupShares)
                .HasForeignKey(gs => gs.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(gs => gs.GroupId);
            entity.HasIndex(gs => gs.UserId);
            entity.HasIndex(gs => gs.CreatedAt);
        });

        // GroupShareContact configuration (many-to-many)
        builder.Entity<GroupShareContact>(entity =>
        {
            entity.HasKey(gsc => new { gsc.GroupShareId, gsc.ContactInfoId });

            entity.HasOne(gsc => gsc.GroupShare)
                .WithMany(gs => gs.SharedContacts)
                .HasForeignKey(gsc => gsc.GroupShareId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(gsc => gsc.ContactInfo)
                .WithMany()
                .HasForeignKey(gsc => gsc.ContactInfoId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Company configuration
        builder.Entity<Company>(entity =>
        {
            entity.HasKey(c => c.Id);
            entity.Property(c => c.Name).HasMaxLength(100).IsRequired();
            entity.Property(c => c.Description).HasMaxLength(500);
            entity.Property(c => c.LogoUrl).HasMaxLength(500);
            entity.Property(c => c.BackgroundImageUrl).HasMaxLength(500);

            entity.HasIndex(c => c.IsContractor);
        });

        // ApkRelease configuration
        builder.Entity<ApkRelease>(entity =>
        {
            entity.HasKey(a => a.Id);
            entity.Property(a => a.Version).HasMaxLength(20).IsRequired();
            entity.Property(a => a.FileName).HasMaxLength(200).IsRequired();
            entity.Property(a => a.ReleaseNotes).HasMaxLength(2000);

            entity.HasOne(a => a.UploadedBy)
                .WithMany()
                .HasForeignKey(a => a.UploadedByUserId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasIndex(a => a.Version);
            entity.HasIndex(a => a.IsLatest);
            entity.HasIndex(a => a.UploadedAt);
        });

        // WebSession configuration
        builder.Entity<WebSession>(entity =>
        {
            entity.HasKey(ws => ws.Id);
            entity.Property(ws => ws.PairingToken).HasMaxLength(256).IsRequired();
            entity.Property(ws => ws.AccessToken).HasMaxLength(2000);
            entity.Property(ws => ws.RefreshToken).HasMaxLength(256);
            entity.Property(ws => ws.UserAgent).HasMaxLength(500);
            entity.Property(ws => ws.IpAddress).HasMaxLength(50);
            entity.Property(ws => ws.DeviceName).HasMaxLength(100);

            entity.HasOne(ws => ws.User)
                .WithMany(u => u.WebSessions)
                .HasForeignKey(ws => ws.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(ws => ws.PairingToken).IsUnique();
            entity.HasIndex(ws => ws.UserId);
        });
    }
}
