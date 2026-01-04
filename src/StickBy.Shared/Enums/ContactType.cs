namespace StickBy.Shared.Enums;

public enum ContactType
{
    // General (0-99)
    Email = 0,
    Phone = 1,
    Address = 2,
    Website = 3,
    Social = 4,
    Custom = 99,

    // Personal Info (100-199)
    Nationality = 100,
    MaritalStatus = 101,
    PlaceOfBirth = 102,
    Education = 103,
    Birthday = 104,

    // Private Contact (200-299)
    Mobile = 200,
    EmergencyContact = 201,

    // Business (300-399)
    Company = 300,
    Position = 301,
    BusinessEmail = 302,
    BusinessPhone = 303,

    // Social Networks (400-499)
    Facebook = 400,
    Instagram = 401,
    LinkedIn = 402,
    Twitter = 403,
    TikTok = 404,
    Snapchat = 405,
    Xing = 406,
    GitHub = 407,

    // Gaming (500-599)
    Steam = 500,
    Discord = 501
}
