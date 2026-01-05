using System.Net.Http.Json;
using System.Net.Http.Headers;
using StickBy.Shared.Enums;
using StickBy.Shared.Models.Auth;
using StickBy.Shared.Models.Companies;
using StickBy.Shared.Models.Contacts;
using StickBy.Shared.Models.Groups;
using StickBy.Shared.Models.Profile;
using StickBy.Shared.Models.Shares;
using StickBy.Shared.Models.WebSession;

namespace StickBy.Web.Services;

public interface IApiService
{
    Task<AuthResponse?> LoginAsync(LoginRequest request);
    Task<AuthResponse?> RegisterAsync(RegisterRequest request);
    void SetAccessToken(string token);
    void ClearAccessToken();

    Task<List<ContactDto>> GetContactsAsync();
    Task<ContactDto?> GetContactAsync(Guid id);
    Task<ContactDto?> CreateContactAsync(CreateContactRequest request);
    Task<ContactDto?> UpdateContactAsync(Guid id, UpdateContactRequest request);
    Task<bool> DeleteContactAsync(Guid id);

    Task<List<ShareDto>> GetSharesAsync();
    Task<ShareDto?> CreateShareAsync(CreateShareRequest request);
    Task<bool> DeleteShareAsync(Guid id);

    Task<List<GroupDto>> GetGroupsAsync();
    Task<List<GroupDto>> GetPendingInvitationsAsync();
    Task<GroupDetailDto?> GetGroupDetailAsync(Guid groupId);
    Task<GroupDto?> CreateGroupAsync(CreateGroupRequest request);
    Task<bool> JoinGroupAsync(Guid groupId);
    Task<bool> DeclineInvitationAsync(Guid groupId);
    Task<bool> LeaveGroupAsync(Guid groupId);
    Task<bool> InviteToGroupAsync(Guid groupId, string email);

    Task<ProfileDto?> GetProfileAsync();
    Task<ProfileDto?> UpdateProfileAsync(UpdateProfileRequest request);
    Task<bool> UpdateProfileImageAsync(string imageUrl);
    Task<bool> UpdateReleaseGroupsAsync(List<UpdateReleaseGroupsRequest> updates);

    Task<List<CompanyDto>> GetCompaniesAsync(bool? isContractor = null);
    Task<CompanyDto?> GetCompanyAsync(Guid companyId);

    // Web Session (QR code pairing)
    Task<WebSessionCreateResponse?> CreateWebSessionAsync();
    Task<WebSessionStatusResponse?> GetWebSessionStatusAsync(string pairingToken);
}

public class ApiService : IApiService
{
    private readonly HttpClient _httpClient;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private string? _accessToken;

    public ApiService(HttpClient httpClient, IHttpContextAccessor httpContextAccessor)
    {
        _httpClient = httpClient;
        _httpContextAccessor = httpContextAccessor;

        // Try to get token from cookie
        var tokenCookie = _httpContextAccessor.HttpContext?.Request.Cookies["access_token"];
        if (!string.IsNullOrEmpty(tokenCookie))
        {
            _accessToken = tokenCookie;
        }
    }

    public void SetAccessToken(string token)
    {
        _accessToken = token;

        // Store in cookie
        _httpContextAccessor.HttpContext?.Response.Cookies.Append("access_token", token, new CookieOptions
        {
            HttpOnly = true,
            Secure = true,
            SameSite = SameSiteMode.Strict,
            Expires = DateTimeOffset.UtcNow.AddDays(7)
        });
    }

    public void ClearAccessToken()
    {
        _accessToken = null;
        _httpContextAccessor.HttpContext?.Response.Cookies.Delete("access_token");
    }

    private void AddAuthHeader(HttpRequestMessage request)
    {
        if (!string.IsNullOrEmpty(_accessToken))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _accessToken);
        }
    }

    private async Task<T?> GetAsync<T>(string url) where T : class
    {
        var request = new HttpRequestMessage(HttpMethod.Get, url);
        AddAuthHeader(request);

        var response = await _httpClient.SendAsync(request);
        if (!response.IsSuccessStatusCode) return null;
        return await response.Content.ReadFromJsonAsync<T>();
    }

    private async Task<TResponse?> PostAsync<TRequest, TResponse>(string url, TRequest content)
        where TResponse : class
    {
        var request = new HttpRequestMessage(HttpMethod.Post, url);
        request.Content = JsonContent.Create(content);
        AddAuthHeader(request);

        var response = await _httpClient.SendAsync(request);
        if (!response.IsSuccessStatusCode) return null;
        return await response.Content.ReadFromJsonAsync<TResponse>();
    }

    private async Task<bool> PostAsync<TRequest>(string url, TRequest? content = default)
    {
        var request = new HttpRequestMessage(HttpMethod.Post, url);
        if (content != null)
        {
            request.Content = JsonContent.Create(content);
        }
        AddAuthHeader(request);

        var response = await _httpClient.SendAsync(request);
        return response.IsSuccessStatusCode;
    }

    private async Task<TResponse?> PutAsync<TRequest, TResponse>(string url, TRequest content)
        where TResponse : class
    {
        var request = new HttpRequestMessage(HttpMethod.Put, url);
        request.Content = JsonContent.Create(content);
        AddAuthHeader(request);

        var response = await _httpClient.SendAsync(request);
        if (!response.IsSuccessStatusCode) return null;
        return await response.Content.ReadFromJsonAsync<TResponse>();
    }

    private async Task<bool> PutAsync<TRequest>(string url, TRequest content)
    {
        var request = new HttpRequestMessage(HttpMethod.Put, url);
        request.Content = JsonContent.Create(content);
        AddAuthHeader(request);

        var response = await _httpClient.SendAsync(request);
        return response.IsSuccessStatusCode;
    }

    private async Task<bool> DeleteAsync(string url)
    {
        var request = new HttpRequestMessage(HttpMethod.Delete, url);
        AddAuthHeader(request);

        var response = await _httpClient.SendAsync(request);
        return response.IsSuccessStatusCode;
    }

    // Auth
    public async Task<AuthResponse?> LoginAsync(LoginRequest request)
    {
        var response = await _httpClient.PostAsJsonAsync("api/auth/login", request);
        if (!response.IsSuccessStatusCode) return null;
        return await response.Content.ReadFromJsonAsync<AuthResponse>();
    }

    public async Task<AuthResponse?> RegisterAsync(RegisterRequest request)
    {
        var response = await _httpClient.PostAsJsonAsync("api/auth/register", request);
        if (!response.IsSuccessStatusCode) return null;
        return await response.Content.ReadFromJsonAsync<AuthResponse>();
    }

    // Contacts
    public async Task<List<ContactDto>> GetContactsAsync()
    {
        return await GetAsync<List<ContactDto>>("api/contacts") ?? new List<ContactDto>();
    }

    public async Task<ContactDto?> GetContactAsync(Guid id)
    {
        return await GetAsync<ContactDto>($"api/contacts/{id}");
    }

    public async Task<ContactDto?> CreateContactAsync(CreateContactRequest request)
    {
        return await PostAsync<CreateContactRequest, ContactDto>("api/contacts", request);
    }

    public async Task<ContactDto?> UpdateContactAsync(Guid id, UpdateContactRequest request)
    {
        return await PutAsync<UpdateContactRequest, ContactDto>($"api/contacts/{id}", request);
    }

    public async Task<bool> DeleteContactAsync(Guid id)
    {
        return await DeleteAsync($"api/contacts/{id}");
    }

    // Shares
    public async Task<List<ShareDto>> GetSharesAsync()
    {
        return await GetAsync<List<ShareDto>>("api/shares") ?? new List<ShareDto>();
    }

    public async Task<ShareDto?> CreateShareAsync(CreateShareRequest request)
    {
        return await PostAsync<CreateShareRequest, ShareDto>("api/shares", request);
    }

    public async Task<bool> DeleteShareAsync(Guid id)
    {
        return await DeleteAsync($"api/shares/{id}");
    }

    // Groups
    public async Task<List<GroupDto>> GetGroupsAsync()
    {
        return await GetAsync<List<GroupDto>>("api/groups") ?? new List<GroupDto>();
    }

    public async Task<List<GroupDto>> GetPendingInvitationsAsync()
    {
        return await GetAsync<List<GroupDto>>("api/groups/invitations") ?? new List<GroupDto>();
    }

    public async Task<GroupDetailDto?> GetGroupDetailAsync(Guid groupId)
    {
        return await GetAsync<GroupDetailDto>($"api/groups/{groupId}");
    }

    public async Task<GroupDto?> CreateGroupAsync(CreateGroupRequest request)
    {
        return await PostAsync<CreateGroupRequest, GroupDto>("api/groups", request);
    }

    public async Task<bool> JoinGroupAsync(Guid groupId)
    {
        return await PostAsync<object>($"api/groups/{groupId}/join");
    }

    public async Task<bool> DeclineInvitationAsync(Guid groupId)
    {
        return await PostAsync<object>($"api/groups/{groupId}/decline");
    }

    public async Task<bool> LeaveGroupAsync(Guid groupId)
    {
        return await PostAsync<object>($"api/groups/{groupId}/leave");
    }

    public async Task<bool> InviteToGroupAsync(Guid groupId, string email)
    {
        return await PostAsync($"api/groups/{groupId}/invite", new { Email = email });
    }

    // Profile
    public async Task<ProfileDto?> GetProfileAsync()
    {
        return await GetAsync<ProfileDto>("api/profile");
    }

    public async Task<ProfileDto?> UpdateProfileAsync(UpdateProfileRequest request)
    {
        return await PutAsync<UpdateProfileRequest, ProfileDto>("api/profile", request);
    }

    public async Task<bool> UpdateProfileImageAsync(string imageUrl)
    {
        return await PutAsync("api/profile/image", new { ImageUrl = imageUrl });
    }

    public async Task<bool> UpdateReleaseGroupsAsync(List<UpdateReleaseGroupsRequest> updates)
    {
        return await PutAsync("api/profile/release-groups/bulk", new BulkUpdateReleaseGroupsRequest { Updates = updates });
    }

    // Companies
    public async Task<List<CompanyDto>> GetCompaniesAsync(bool? isContractor = null)
    {
        var url = isContractor.HasValue
            ? $"api/company?isContractor={isContractor.Value.ToString().ToLower()}"
            : "api/company";
        return await GetAsync<List<CompanyDto>>(url) ?? new List<CompanyDto>();
    }

    public async Task<CompanyDto?> GetCompanyAsync(Guid companyId)
    {
        return await GetAsync<CompanyDto>($"api/company/{companyId}");
    }

    // Web Session (QR code pairing)
    public async Task<WebSessionCreateResponse?> CreateWebSessionAsync()
    {
        var response = await _httpClient.PostAsync("api/web-session", null);
        if (!response.IsSuccessStatusCode) return null;
        return await response.Content.ReadFromJsonAsync<WebSessionCreateResponse>();
    }

    public async Task<WebSessionStatusResponse?> GetWebSessionStatusAsync(string pairingToken)
    {
        return await GetAsync<WebSessionStatusResponse>($"api/web-session/{pairingToken}/status");
    }
}
