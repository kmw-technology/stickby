using Microsoft.EntityFrameworkCore;
using StickBy.Infrastructure.Data;
using StickBy.Infrastructure.Entities;
using StickBy.Shared.Models.Companies;

namespace StickBy.Api.Services;

public interface ICompanyService
{
    Task<List<CompanyDto>> GetCompaniesAsync(bool? isContractor = null);
    Task<CompanyDto?> GetCompanyAsync(Guid companyId);
}

public class CompanyService : ICompanyService
{
    private readonly StickByDbContext _context;

    public CompanyService(StickByDbContext context)
    {
        _context = context;
    }

    public async Task<List<CompanyDto>> GetCompaniesAsync(bool? isContractor = null)
    {
        var query = _context.Companies.AsQueryable();

        if (isContractor.HasValue)
        {
            query = query.Where(c => c.IsContractor == isContractor.Value);
        }

        var companies = await query
            .OrderBy(c => c.Name)
            .ToListAsync();

        return companies.Select(MapToDto).ToList();
    }

    public async Task<CompanyDto?> GetCompanyAsync(Guid companyId)
    {
        var company = await _context.Companies.FindAsync(companyId);
        return company == null ? null : MapToDto(company);
    }

    private static CompanyDto MapToDto(Company company)
    {
        return new CompanyDto
        {
            Id = company.Id,
            Name = company.Name,
            Description = company.Description,
            LogoUrl = company.LogoUrl,
            BackgroundImageUrl = company.BackgroundImageUrl,
            IsContractor = company.IsContractor,
            FollowerCount = company.FollowerCount,
            CreatedAt = company.CreatedAt
        };
    }
}
