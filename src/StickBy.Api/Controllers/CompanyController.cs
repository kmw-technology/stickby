using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StickBy.Api.Services;
using StickBy.Shared.Models.Companies;

namespace StickBy.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CompanyController : ControllerBase
{
    private readonly ICompanyService _companyService;

    public CompanyController(ICompanyService companyService)
    {
        _companyService = companyService;
    }

    [HttpGet]
    public async Task<ActionResult<List<CompanyDto>>> GetCompanies([FromQuery] bool? isContractor = null)
    {
        var companies = await _companyService.GetCompaniesAsync(isContractor);
        return Ok(companies);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<CompanyDto>> GetCompany(Guid id)
    {
        var company = await _companyService.GetCompanyAsync(id);

        if (company == null)
            return NotFound();

        return Ok(company);
    }
}
