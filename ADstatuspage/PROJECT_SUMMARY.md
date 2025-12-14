# ADstatuspage Project Summary

## Project Created
A complete ASP.NET Core 8.0 Razor Pages application for monitoring Active Directory infrastructure.

## Location
`SaveFolder/ADstatuspage/`

## What Was Built

### 1. Project Structure
```
ADstatuspage/
├── ADstatuspage.sln                          # Solution file
├── .gitignore                                # Git ignore rules
├── README.md                                 # Comprehensive documentation
└── ADstatuspage/                             # Main project
    ├── Data/                                 # Database context and entities
    │   ├── ApplicationDbContext.cs
    │   └── HealthCheckLog.cs
    ├── Services/                             # Business logic
    │   ├── IADHealthService.cs
    │   └── ADHealthService.cs
    ├── Models/                               # DTOs
    │   └── HealthModels.cs
    ├── Pages/                                # Razor Pages UI
    │   ├── Index.cshtml & .cs                # Dashboard
    │   ├── DomainControllers.cshtml & .cs    # DC monitoring
    │   ├── Replication.cshtml & .cs          # Replication status
    │   ├── Dns.cshtml & .cs                  # DNS health
    │   ├── Services.cshtml & .cs             # Service monitoring
    │   └── Shared/_Layout.cshtml             # Main layout
    ├── Migrations/                           # EF Core migrations
    │   └── 20251212212438_InitialCreate.cs
    ├── wwwroot/                              # Static files
    │   └── css/site.css                      # Custom styles
    ├── Program.cs                            # Application startup
    ├── appsettings.json                      # Configuration
    └── ADstatuspage.csproj                   # Project file
```

### 2. Key Features Implemented

#### Authentication & Security
- Windows Authentication (Negotiate scheme) configured
- No anonymous access allowed
- Integrated with Windows domain authentication

#### Health Monitoring Services
- **Domain Controllers**: Ping, LDAP (389), LDAPS (636) connectivity tests
- **Replication**: Parse `repadmin /replsummary` for failures and latency
- **DNS**: Test resolution for `_ldap._tcp.dc._msdcs` and other critical records
- **Services**: Check NTDS, DNS, DFSR service status via PowerShell

#### Data Layer
- Entity Framework Core 8.0 with SQL Server LocalDB
- `HealthCheckLog` table for operational logging
- Initial migration created and ready to apply

#### Caching
- In-memory caching with 60-second expiration
- Reduces load on Active Directory infrastructure
- Implemented per-section (DCs, Replication, DNS, Services)

#### User Interface
- Bootstrap 5 responsive design
- Status indicators with color coding:
  - Green (Up): All systems operational
  - Yellow (Degraded): Partial functionality
  - Red (Down): Service unavailable
- Navigation menu with all monitoring sections
- Real-time data display with timestamps

### 3. NuGet Packages Added
- `Microsoft.EntityFrameworkCore.SqlServer` (8.0.11)
- `Microsoft.EntityFrameworkCore.Tools` (8.0.11)
- `Microsoft.AspNetCore.Authentication.Negotiate` (8.0.11)
- `System.DirectoryServices` (8.0.0)
- `System.DirectoryServices.AccountManagement` (8.0.1)
- `Microsoft.PowerShell.SDK` (7.4.6)
- `Microsoft.CodeAnalysis.Common` (4.9.2) - for compatibility

### 4. Technologies Used
- **Framework**: ASP.NET Core 8.0
- **UI**: Razor Pages + Bootstrap 5
- **ORM**: Entity Framework Core 8.0
- **Database**: SQL Server LocalDB (configurable)
- **AD Integration**: System.DirectoryServices
- **Automation**: PowerShell SDK
- **Authentication**: Windows Authentication (Kerberos/NTLM)
- **Caching**: Microsoft.Extensions.Caching.Memory

### 5. Deployment Ready Features

#### Documentation
- Complete README.md with:
  - Prerequisites
  - Local development setup
  - IIS deployment steps
  - Windows Authentication configuration
  - Troubleshooting guide
  - Security considerations

#### Database
- EF Core migrations included
- Commands documented for:
  - `dotnet ef migrations add`
  - `dotnet ef database update`

#### Configuration
- Connection strings in appsettings.json
- Environment-specific settings
- Configurable cache expiration

### 6. Health Check Implementation Details

#### ADHealthService Methods
1. `GetDomainControllers()`: 
   - Uses `Domain.GetCurrentDomain()` from System.DirectoryServices
   - Falls back to PowerShell if DirectoryServices fails
   - Tests ping, LDAP, and LDAPS connectivity
   - Returns DC name, site, OS version, and status

2. `GetReplicationSummary()`:
   - Executes `repadmin /replsummary` via PowerShell
   - Parses output for failures and latency metrics
   - Returns failure count, max/avg latency, and failure list

3. `GetDnsHealth()`:
   - Uses PowerShell `Resolve-DnsName` cmdlet
   - Tests critical AD DNS records
   - Checks forwarder health
   - Returns test results with success/failure status

4. `GetAdServicesStatus()`:
   - Queries services on each DC via PowerShell `Get-Service`
   - Checks NTDS, DNS, and DFSR services
   - Returns service status per DC
   - Includes timeout handling (15 seconds per DC)

5. `GetOverallHealth()`:
   - Aggregates status from all sections
   - Provides unified health view
   - Used on dashboard page

### 7. Security Considerations Addressed
- Windows Authentication required (no anonymous access)
- Service account needs AD read permissions
- No hardcoded credentials
- HTTPS recommended for production
- Least-privilege guidance documented
- Input validation on PowerShell commands
- Timeout protection on external calls

### 8. Building and Running

#### Local Development
```bash
cd SaveFolder/ADstatuspage
dotnet restore
dotnet build
dotnet ef database update
dotnet run
```
Access at: https://localhost:5001

#### Production Deployment
1. Publish: `dotnet publish -c Release -o ./publish`
2. Install .NET 8 Hosting Bundle on IIS server
3. Create IIS application pool (No Managed Code)
4. Configure Windows Authentication
5. Deploy published files
6. Apply database migrations

### 9. Testing Status
- ✅ Project builds successfully
- ✅ All NuGet packages restored
- ✅ EF Core migrations created
- ✅ Code review completed (minor doc fixes applied)
- ⚠️ Runtime testing requires Windows Server with AD
- ⚠️ CodeQL check could not complete (git diff issue, not code issue)

### 10. Future Enhancements (Not Implemented)
- Auto-refresh UI capability
- Historical health data reporting
- Email alerting on failures
- Performance counter monitoring
- Group Policy status checks
- Certificate expiration monitoring

## Deliverables Checklist
- ✅ Complete ASP.NET Core 8.0 project
- ✅ All required NuGet packages
- ✅ Windows Authentication configured
- ✅ Database context and migrations
- ✅ All 5 Razor Pages (Index, DCs, Replication, DNS, Services)
- ✅ Health service implementation with caching
- ✅ Custom CSS for status indicators
- ✅ Comprehensive README with IIS deployment
- ✅ .gitignore for clean repository
- ✅ Solution file for easy opening in Visual Studio

## Notes
- Application is Windows-specific (by design)
- Requires domain-joined Windows Server for full functionality
- PowerShell cmdlets may require RSAT tools for best results
- Falls back gracefully when PowerShell modules unavailable
- Build warnings about Windows-only APIs are expected and normal
