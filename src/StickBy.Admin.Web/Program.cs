using Microsoft.EntityFrameworkCore;
using StickBy.Admin.Web.Components;
using StickBy.Admin.Web.Services;
using StickBy.Infrastructure.Data;

var builder = WebApplication.CreateBuilder(args);

// Add database context
builder.Services.AddDbContext<StickByDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// Add admin services
builder.Services.AddScoped<IAdminService, AdminService>();

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

var app = builder.Build();

// PathBase for reverse proxy deployment
var pathBase = builder.Configuration["PathBase"];
if (!string.IsNullOrEmpty(pathBase))
{
    app.UsePathBase(pathBase);
}

// Apply migrations on startup
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<StickByDbContext>();
    db.Database.Migrate();
}

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();
app.UseAntiforgery();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

// Health check endpoint
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }));

// APK Download endpoint - streams file directly to browser
app.MapGet("/api/apk-download/{id:guid}", async (Guid id, StickByDbContext db) =>
{
    var release = await db.ApkReleases.FindAsync(id);
    if (release == null || release.FileData == null)
        return Results.NotFound();

    return Results.File(
        release.FileData,
        "application/vnd.android.package-archive",
        release.FileName);
});

app.Run();
