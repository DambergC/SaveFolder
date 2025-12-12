using Microsoft.EntityFrameworkCore;

namespace ADstatuspage.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<HealthCheckLog> HealthCheckLogs { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<HealthCheckLog>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Section).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Status).IsRequired().HasMaxLength(50);
            entity.Property(e => e.OptionalMessage).HasMaxLength(1000);
        });
    }
}
