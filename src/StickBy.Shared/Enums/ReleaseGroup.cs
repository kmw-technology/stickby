namespace StickBy.Shared.Enums;

[Flags]
public enum ReleaseGroup
{
    None = 0,
    Family = 1,
    Friends = 2,
    Business = 4,
    Leisure = 8,
    All = Family | Friends | Business | Leisure
}
