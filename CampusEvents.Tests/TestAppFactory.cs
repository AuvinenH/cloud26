using CampusEvents.Data;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace CampusEvents.Tests;

/// <summary>
/// Boots the real app (Program.cs) but replaces PostgreSQL with an
/// in-memory EF Core provider, so tests run anywhere — including CI.
/// </summary>
public class TestAppFactory : WebApplicationFactory<Program>
{
    // Unique name per factory instance → test classes do not share state.
    // (Tests inside ONE class share the factory via IClassFixture, so they share this database.)
    private readonly string _databaseName = $"CampusEventsTests-{Guid.NewGuid()}";

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            // Remove the real PostgreSQL registration from Program.cs...
            services.RemoveAll<DbContextOptions<AppDbContext>>();
            services.RemoveAll<IDbContextOptionsConfiguration<AppDbContext>>();

            // ...and register the in-memory provider instead.
            services.AddDbContext<AppDbContext>(options =>
                options.UseInMemoryDatabase(_databaseName));
        });
    }
}