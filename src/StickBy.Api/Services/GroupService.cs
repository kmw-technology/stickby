using Microsoft.EntityFrameworkCore;
using StickBy.Infrastructure.Data;
using StickBy.Infrastructure.Entities;
using StickBy.Shared.Enums;
using StickBy.Shared.Models.Contacts;
using StickBy.Shared.Models.Groups;

namespace StickBy.Api.Services;

public interface IGroupService
{
    Task<List<GroupDto>> GetGroupsAsync(Guid userId);
    Task<GroupDetailDto?> GetGroupDetailAsync(Guid userId, Guid groupId);
    Task<GroupDto> CreateGroupAsync(Guid userId, CreateGroupRequest request);
    Task<GroupDto?> UpdateGroupAsync(Guid userId, Guid groupId, UpdateGroupRequest request);
    Task<bool> DeleteGroupAsync(Guid userId, Guid groupId);
    Task<bool> InviteToGroupAsync(Guid userId, Guid groupId, InviteToGroupRequest request);
    Task<bool> JoinGroupAsync(Guid userId, Guid groupId);
    Task<bool> DeclineInvitationAsync(Guid userId, Guid groupId);
    Task<bool> LeaveGroupAsync(Guid userId, Guid groupId);
    Task<bool> RemoveMemberAsync(Guid userId, Guid groupId, Guid memberId);
    Task<bool> UpdateMemberRoleAsync(Guid userId, Guid groupId, Guid memberId, GroupMemberRole role);
    Task<List<GroupShareDto>> GetGroupSharesAsync(Guid userId, Guid groupId);
    Task<GroupShareDto?> ShareToGroupAsync(Guid userId, Guid groupId, ShareToGroupRequest request);
    Task<bool> DeleteGroupShareAsync(Guid userId, Guid groupId, Guid shareId);
    Task<List<GroupDto>> GetPendingInvitationsAsync(Guid userId);
}

public class GroupService : IGroupService
{
    private readonly StickByDbContext _context;
    private readonly IEncryptionService _encryptionService;

    public GroupService(StickByDbContext context, IEncryptionService encryptionService)
    {
        _context = context;
        _encryptionService = encryptionService;
    }

    public async Task<List<GroupDto>> GetGroupsAsync(Guid userId)
    {
        var groups = await _context.GroupMembers
            .Where(gm => gm.UserId == userId && gm.Status == GroupMemberStatus.Active)
            .Include(gm => gm.Group)
                .ThenInclude(g => g.Members)
            .Select(gm => new GroupDto
            {
                Id = gm.Group.Id,
                Name = gm.Group.Name,
                Description = gm.Group.Description,
                CoverImageUrl = gm.Group.CoverImageUrl,
                MemberCount = gm.Group.Members.Count(m => m.Status == GroupMemberStatus.Active),
                MyRole = gm.Role,
                MyStatus = gm.Status,
                CreatedAt = gm.Group.CreatedAt
            })
            .OrderByDescending(g => g.CreatedAt)
            .ToListAsync();

        return groups;
    }

    public async Task<List<GroupDto>> GetPendingInvitationsAsync(Guid userId)
    {
        var invitations = await _context.GroupMembers
            .Where(gm => gm.UserId == userId && gm.Status == GroupMemberStatus.Pending)
            .Include(gm => gm.Group)
                .ThenInclude(g => g.Members)
            .Select(gm => new GroupDto
            {
                Id = gm.Group.Id,
                Name = gm.Group.Name,
                Description = gm.Group.Description,
                MemberCount = gm.Group.Members.Count(m => m.Status == GroupMemberStatus.Active),
                MyRole = gm.Role,
                MyStatus = gm.Status,
                CreatedAt = gm.Group.CreatedAt
            })
            .ToListAsync();

        return invitations;
    }

    public async Task<GroupDetailDto?> GetGroupDetailAsync(Guid userId, Guid groupId)
    {
        var membership = await _context.GroupMembers
            .FirstOrDefaultAsync(gm => gm.GroupId == groupId && gm.UserId == userId &&
                (gm.Status == GroupMemberStatus.Active || gm.Status == GroupMemberStatus.Pending));

        if (membership == null)
            return null;

        var group = await _context.Groups
            .Include(g => g.CreatedByUser)
            .Include(g => g.Members)
                .ThenInclude(m => m.User)
            .FirstOrDefaultAsync(g => g.Id == groupId);

        if (group == null)
            return null;

        var recentShares = await GetGroupSharesAsync(userId, groupId);

        return new GroupDetailDto
        {
            Id = group.Id,
            Name = group.Name,
            Description = group.Description,
            CoverImageUrl = group.CoverImageUrl,
            CreatedByUserId = group.CreatedByUserId,
            CreatedByUserName = group.CreatedByUser.DisplayName,
            CreatedAt = group.CreatedAt,
            MyRole = membership.Role,
            MyStatus = membership.Status,
            Members = group.Members
                .Where(m => m.Status == GroupMemberStatus.Active || m.Status == GroupMemberStatus.Pending)
                .Select(m => new GroupMemberDto
                {
                    UserId = m.UserId,
                    DisplayName = m.User.DisplayName,
                    Email = m.User.Email ?? "",
                    Role = m.Role,
                    Status = m.Status,
                    JoinedAt = m.JoinedAt
                })
                .OrderBy(m => m.Role)
                .ThenBy(m => m.DisplayName)
                .ToList(),
            RecentShares = recentShares.Take(10).ToList()
        };
    }

    public async Task<GroupDto> CreateGroupAsync(Guid userId, CreateGroupRequest request)
    {
        var group = new Group
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            Description = request.Description,
            CreatedByUserId = userId
        };

        // Add creator as owner
        var ownerMember = new GroupMember
        {
            GroupId = group.Id,
            UserId = userId,
            Role = GroupMemberRole.Owner,
            Status = GroupMemberStatus.Active
        };

        _context.Groups.Add(group);
        _context.GroupMembers.Add(ownerMember);
        await _context.SaveChangesAsync();

        return new GroupDto
        {
            Id = group.Id,
            Name = group.Name,
            Description = group.Description,
            MemberCount = 1,
            MyRole = GroupMemberRole.Owner,
            MyStatus = GroupMemberStatus.Active,
            CreatedAt = group.CreatedAt
        };
    }

    public async Task<GroupDto?> UpdateGroupAsync(Guid userId, Guid groupId, UpdateGroupRequest request)
    {
        var membership = await _context.GroupMembers
            .FirstOrDefaultAsync(gm => gm.GroupId == groupId && gm.UserId == userId &&
                (gm.Role == GroupMemberRole.Owner || gm.Role == GroupMemberRole.Admin) &&
                gm.Status == GroupMemberStatus.Active);

        if (membership == null)
            return null;

        var group = await _context.Groups
            .Include(g => g.Members)
            .FirstOrDefaultAsync(g => g.Id == groupId);

        if (group == null)
            return null;

        group.Name = request.Name;
        group.Description = request.Description;

        await _context.SaveChangesAsync();

        return new GroupDto
        {
            Id = group.Id,
            Name = group.Name,
            Description = group.Description,
            MemberCount = group.Members.Count(m => m.Status == GroupMemberStatus.Active),
            MyRole = membership.Role,
            MyStatus = membership.Status,
            CreatedAt = group.CreatedAt
        };
    }

    public async Task<bool> DeleteGroupAsync(Guid userId, Guid groupId)
    {
        var membership = await _context.GroupMembers
            .FirstOrDefaultAsync(gm => gm.GroupId == groupId && gm.UserId == userId &&
                gm.Role == GroupMemberRole.Owner);

        if (membership == null)
            return false;

        var group = await _context.Groups.FindAsync(groupId);
        if (group == null)
            return false;

        _context.Groups.Remove(group);
        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> InviteToGroupAsync(Guid userId, Guid groupId, InviteToGroupRequest request)
    {
        // Check if user has permission to invite
        var membership = await _context.GroupMembers
            .FirstOrDefaultAsync(gm => gm.GroupId == groupId && gm.UserId == userId &&
                (gm.Role == GroupMemberRole.Owner || gm.Role == GroupMemberRole.Admin) &&
                gm.Status == GroupMemberStatus.Active);

        if (membership == null)
            return false;

        // Find user by email
        var invitee = await _context.Users
            .FirstOrDefaultAsync(u => u.Email == request.Email);

        if (invitee == null)
            return false;

        // Check if already a member
        var existingMembership = await _context.GroupMembers
            .FirstOrDefaultAsync(gm => gm.GroupId == groupId && gm.UserId == invitee.Id);

        if (existingMembership != null)
        {
            if (existingMembership.Status == GroupMemberStatus.Left ||
                existingMembership.Status == GroupMemberStatus.Declined)
            {
                existingMembership.Status = GroupMemberStatus.Pending;
                existingMembership.JoinedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
                return true;
            }
            return false; // Already member or pending
        }

        var newMember = new GroupMember
        {
            GroupId = groupId,
            UserId = invitee.Id,
            Role = GroupMemberRole.Member,
            Status = GroupMemberStatus.Pending
        };

        _context.GroupMembers.Add(newMember);
        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> JoinGroupAsync(Guid userId, Guid groupId)
    {
        var membership = await _context.GroupMembers
            .FirstOrDefaultAsync(gm => gm.GroupId == groupId && gm.UserId == userId &&
                gm.Status == GroupMemberStatus.Pending);

        if (membership == null)
            return false;

        membership.Status = GroupMemberStatus.Active;
        membership.JoinedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> DeclineInvitationAsync(Guid userId, Guid groupId)
    {
        var membership = await _context.GroupMembers
            .FirstOrDefaultAsync(gm => gm.GroupId == groupId && gm.UserId == userId &&
                gm.Status == GroupMemberStatus.Pending);

        if (membership == null)
            return false;

        membership.Status = GroupMemberStatus.Declined;

        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> LeaveGroupAsync(Guid userId, Guid groupId)
    {
        var membership = await _context.GroupMembers
            .FirstOrDefaultAsync(gm => gm.GroupId == groupId && gm.UserId == userId &&
                gm.Status == GroupMemberStatus.Active);

        if (membership == null)
            return false;

        // Owner cannot leave
        if (membership.Role == GroupMemberRole.Owner)
            return false;

        membership.Status = GroupMemberStatus.Left;

        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> RemoveMemberAsync(Guid userId, Guid groupId, Guid memberId)
    {
        // Check if user has permission
        var myMembership = await _context.GroupMembers
            .FirstOrDefaultAsync(gm => gm.GroupId == groupId && gm.UserId == userId &&
                (gm.Role == GroupMemberRole.Owner || gm.Role == GroupMemberRole.Admin) &&
                gm.Status == GroupMemberStatus.Active);

        if (myMembership == null)
            return false;

        var targetMembership = await _context.GroupMembers
            .FirstOrDefaultAsync(gm => gm.GroupId == groupId && gm.UserId == memberId);

        if (targetMembership == null)
            return false;

        // Cannot remove owner
        if (targetMembership.Role == GroupMemberRole.Owner)
            return false;

        // Admin cannot remove other admins
        if (myMembership.Role == GroupMemberRole.Admin && targetMembership.Role == GroupMemberRole.Admin)
            return false;

        _context.GroupMembers.Remove(targetMembership);
        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> UpdateMemberRoleAsync(Guid userId, Guid groupId, Guid memberId, GroupMemberRole role)
    {
        // Only owner can change roles
        var myMembership = await _context.GroupMembers
            .FirstOrDefaultAsync(gm => gm.GroupId == groupId && gm.UserId == userId &&
                gm.Role == GroupMemberRole.Owner && gm.Status == GroupMemberStatus.Active);

        if (myMembership == null)
            return false;

        var targetMembership = await _context.GroupMembers
            .FirstOrDefaultAsync(gm => gm.GroupId == groupId && gm.UserId == memberId &&
                gm.Status == GroupMemberStatus.Active);

        if (targetMembership == null)
            return false;

        // Cannot change owner role or make someone else owner
        if (targetMembership.Role == GroupMemberRole.Owner || role == GroupMemberRole.Owner)
            return false;

        targetMembership.Role = role;
        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<List<GroupShareDto>> GetGroupSharesAsync(Guid userId, Guid groupId)
    {
        // Check membership
        var membership = await _context.GroupMembers
            .FirstOrDefaultAsync(gm => gm.GroupId == groupId && gm.UserId == userId &&
                gm.Status == GroupMemberStatus.Active);

        if (membership == null)
            return new List<GroupShareDto>();

        var shares = await _context.GroupShares
            .Where(gs => gs.GroupId == groupId)
            .Include(gs => gs.User)
            .Include(gs => gs.SharedContacts)
                .ThenInclude(sc => sc.ContactInfo)
            .OrderByDescending(gs => gs.CreatedAt)
            .ToListAsync();

        return shares.Select(gs => new GroupShareDto
        {
            Id = gs.Id,
            UserId = gs.UserId,
            UserDisplayName = gs.User.DisplayName,
            Message = gs.Message,
            CreatedAt = gs.CreatedAt,
            Contacts = gs.SharedContacts.Select(sc => new ContactDto
            {
                Id = sc.ContactInfo.Id,
                Type = sc.ContactInfo.Type,
                Label = sc.ContactInfo.Label,
                Value = _encryptionService.Decrypt(sc.ContactInfo.EncryptedValue, gs.UserId),
                SortOrder = sc.ContactInfo.SortOrder
            }).OrderBy(c => c.SortOrder).ToList()
        }).ToList();
    }

    public async Task<GroupShareDto?> ShareToGroupAsync(Guid userId, Guid groupId, ShareToGroupRequest request)
    {
        // Check membership
        var membership = await _context.GroupMembers
            .FirstOrDefaultAsync(gm => gm.GroupId == groupId && gm.UserId == userId &&
                gm.Status == GroupMemberStatus.Active);

        if (membership == null)
            return null;

        // Verify all contacts belong to user
        var validContactIds = await _context.ContactInfos
            .Where(c => c.UserId == userId && request.ContactIds.Contains(c.Id))
            .Select(c => c.Id)
            .ToListAsync();

        if (validContactIds.Count != request.ContactIds.Count)
            return null;

        var groupShare = new GroupShare
        {
            Id = Guid.NewGuid(),
            GroupId = groupId,
            UserId = userId,
            Message = request.Message
        };

        groupShare.SharedContacts = validContactIds.Select(cid => new GroupShareContact
        {
            GroupShareId = groupShare.Id,
            ContactInfoId = cid
        }).ToList();

        _context.GroupShares.Add(groupShare);
        await _context.SaveChangesAsync();

        var user = await _context.Users.FindAsync(userId);
        var contacts = await _context.ContactInfos
            .Where(c => validContactIds.Contains(c.Id))
            .ToListAsync();

        return new GroupShareDto
        {
            Id = groupShare.Id,
            UserId = userId,
            UserDisplayName = user?.DisplayName ?? "",
            Message = groupShare.Message,
            CreatedAt = groupShare.CreatedAt,
            Contacts = contacts.Select(c => new ContactDto
            {
                Id = c.Id,
                Type = c.Type,
                Label = c.Label,
                Value = _encryptionService.Decrypt(c.EncryptedValue, userId),
                SortOrder = c.SortOrder
            }).OrderBy(c => c.SortOrder).ToList()
        };
    }

    public async Task<bool> DeleteGroupShareAsync(Guid userId, Guid groupId, Guid shareId)
    {
        var share = await _context.GroupShares
            .FirstOrDefaultAsync(gs => gs.Id == shareId && gs.GroupId == groupId && gs.UserId == userId);

        if (share == null)
            return false;

        _context.GroupShares.Remove(share);
        await _context.SaveChangesAsync();

        return true;
    }
}
