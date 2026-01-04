using System.Security.Cryptography;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using StickBy.Infrastructure.Data;
using StickBy.Infrastructure.Entities;
using StickBy.Shared.Models.Auth;

namespace StickBy.Api.Services;

public interface IAuthService
{
    Task<AuthResponse?> RegisterAsync(RegisterRequest request, string? ipAddress);
    Task<AuthResponse?> LoginAsync(LoginRequest request, string? ipAddress);
    Task<string?> RequestMagicLinkAsync(MagicLinkRequest request);
    Task<AuthResponse?> VerifyMagicLinkAsync(MagicLinkVerifyRequest request, string? ipAddress);
    Task<AuthResponse?> RefreshTokenAsync(string refreshToken, string? ipAddress);
    Task RevokeTokenAsync(string refreshToken, string? ipAddress);
}

public class AuthService : IAuthService
{
    private readonly UserManager<User> _userManager;
    private readonly StickByDbContext _context;
    private readonly IJwtService _jwtService;
    private readonly IConfiguration _configuration;

    public AuthService(
        UserManager<User> userManager,
        StickByDbContext context,
        IJwtService jwtService,
        IConfiguration configuration)
    {
        _userManager = userManager;
        _context = context;
        _jwtService = jwtService;
        _configuration = configuration;
    }

    public async Task<AuthResponse?> RegisterAsync(RegisterRequest request, string? ipAddress)
    {
        var existingUser = await _userManager.FindByEmailAsync(request.Email);
        if (existingUser != null)
            return null;

        var user = new User
        {
            Email = request.Email,
            UserName = request.Email,
            DisplayName = request.DisplayName,
            EmailConfirmed = false
        };

        var result = await _userManager.CreateAsync(user, request.Password);
        if (!result.Succeeded)
            return null;

        return await GenerateAuthResponseAsync(user, ipAddress);
    }

    public async Task<AuthResponse?> LoginAsync(LoginRequest request, string? ipAddress)
    {
        var user = await _userManager.FindByEmailAsync(request.Email);
        if (user == null || !user.IsActive)
            return null;

        var isValid = await _userManager.CheckPasswordAsync(user, request.Password);
        if (!isValid)
            return null;

        user.LastLoginAt = DateTime.UtcNow;
        await _userManager.UpdateAsync(user);

        return await GenerateAuthResponseAsync(user, ipAddress);
    }

    public async Task<string?> RequestMagicLinkAsync(MagicLinkRequest request)
    {
        var user = await _userManager.FindByEmailAsync(request.Email);
        if (user == null || !user.IsActive)
            return null;

        // Invalidate existing magic links
        var existingLinks = await _context.MagicLinks
            .Where(ml => ml.UserId == user.Id && !ml.IsUsed)
            .ToListAsync();

        foreach (var link in existingLinks)
        {
            link.IsUsed = true;
        }

        // Generate new magic link
        var token = GenerateSecureToken();
        var expiryMinutes = int.Parse(_configuration["MagicLink:ExpiryMinutes"] ?? "15");

        var magicLink = new MagicLink
        {
            UserId = user.Id,
            Token = token,
            ExpiresAt = DateTime.UtcNow.AddMinutes(expiryMinutes)
        };

        _context.MagicLinks.Add(magicLink);
        await _context.SaveChangesAsync();

        return token;
    }

    public async Task<AuthResponse?> VerifyMagicLinkAsync(MagicLinkVerifyRequest request, string? ipAddress)
    {
        var magicLink = await _context.MagicLinks
            .Include(ml => ml.User)
            .FirstOrDefaultAsync(ml => ml.Token == request.Token);

        if (magicLink == null || !magicLink.IsValid || !magicLink.User.IsActive)
            return null;

        magicLink.IsUsed = true;
        magicLink.UsedAt = DateTime.UtcNow;

        magicLink.User.LastLoginAt = DateTime.UtcNow;
        if (!magicLink.User.EmailConfirmed)
        {
            magicLink.User.EmailConfirmed = true;
        }

        await _context.SaveChangesAsync();

        return await GenerateAuthResponseAsync(magicLink.User, ipAddress);
    }

    public async Task<AuthResponse?> RefreshTokenAsync(string refreshToken, string? ipAddress)
    {
        var token = await _context.RefreshTokens
            .Include(rt => rt.User)
            .FirstOrDefaultAsync(rt => rt.Token == refreshToken);

        if (token == null || !token.IsActive || !token.User.IsActive)
            return null;

        // Rotate refresh token
        var newRefreshToken = CreateRefreshToken(token.User.Id, ipAddress);
        token.RevokedAt = DateTime.UtcNow;
        token.RevokedByIp = ipAddress;
        token.ReplacedByToken = newRefreshToken.Token;

        _context.RefreshTokens.Add(newRefreshToken);
        await _context.SaveChangesAsync();

        var accessToken = _jwtService.GenerateAccessToken(token.User);

        return new AuthResponse
        {
            AccessToken = accessToken,
            RefreshToken = newRefreshToken.Token,
            ExpiresAt = DateTime.UtcNow.AddMinutes(
                int.Parse(_configuration["Jwt:ExpiryMinutes"] ?? "15")),
            User = new UserDto
            {
                Id = token.User.Id,
                Email = token.User.Email ?? string.Empty,
                DisplayName = token.User.DisplayName
            }
        };
    }

    public async Task RevokeTokenAsync(string refreshToken, string? ipAddress)
    {
        var token = await _context.RefreshTokens
            .FirstOrDefaultAsync(rt => rt.Token == refreshToken);

        if (token != null && token.IsActive)
        {
            token.RevokedAt = DateTime.UtcNow;
            token.RevokedByIp = ipAddress;
            await _context.SaveChangesAsync();
        }
    }

    private async Task<AuthResponse> GenerateAuthResponseAsync(User user, string? ipAddress)
    {
        var accessToken = _jwtService.GenerateAccessToken(user);
        var refreshToken = CreateRefreshToken(user.Id, ipAddress);

        _context.RefreshTokens.Add(refreshToken);
        await _context.SaveChangesAsync();

        return new AuthResponse
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken.Token,
            ExpiresAt = DateTime.UtcNow.AddMinutes(
                int.Parse(_configuration["Jwt:ExpiryMinutes"] ?? "15")),
            User = new UserDto
            {
                Id = user.Id,
                Email = user.Email ?? string.Empty,
                DisplayName = user.DisplayName
            }
        };
    }

    private RefreshToken CreateRefreshToken(Guid userId, string? ipAddress)
    {
        var expiryDays = int.Parse(_configuration["Jwt:RefreshTokenExpiryDays"] ?? "7");
        return new RefreshToken
        {
            UserId = userId,
            Token = _jwtService.GenerateRefreshToken(),
            ExpiresAt = DateTime.UtcNow.AddDays(expiryDays),
            CreatedByIp = ipAddress
        };
    }

    private static string GenerateSecureToken()
    {
        var bytes = new byte[32];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(bytes);
        return Convert.ToBase64String(bytes)
            .Replace("+", "-")
            .Replace("/", "_")
            .TrimEnd('=');
    }
}
