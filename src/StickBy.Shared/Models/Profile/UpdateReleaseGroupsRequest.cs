using StickBy.Shared.Enums;

namespace StickBy.Shared.Models.Profile;

public class UpdateReleaseGroupsRequest
{
    public Guid ContactId { get; set; }
    public ReleaseGroup ReleaseGroups { get; set; }
}

public class BulkUpdateReleaseGroupsRequest
{
    public List<UpdateReleaseGroupsRequest> Updates { get; set; } = new();
}
