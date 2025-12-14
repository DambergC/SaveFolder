# AD Status Dashboard

An ASP.NET Core (.NET 8) Razor Pages application that provides real-time monitoring and health checking for Active Directory infrastructure.

## Features

- **Domain Controller Monitoring**: Real-time health status with ping, LDAP, and LDAPS connectivity tests
- **Replication Status**: Monitor AD replication health, failures, and latency using `repadmin`
- **DNS Health Checks**: Test DNS resolution for critical AD records and forwarder functionality
- **Service Monitoring**: Check critical AD services (NTDS, DNS, DFSR) across domain controllers
- **Windows Authentication**: Secure access using Kerberos/NTLM authentication
- **In-Memory Caching**: Short-lived (60 second) caching to reduce AD query load
- **LocalDB Logging**: Minimal logging via Entity Framework Core for health check tracking

## Prerequisites

### Development Environment
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) or later
- Visual Studio 2022 or VS Code (optional)
- SQL Server LocalDB (included with Visual Studio or available as standalone install)

### Production Environment
- Windows Server (2016 or later recommended)
- Internet Information Services (IIS) 10.0+
- .NET 8 Runtime (ASP.NET Core)
- SQL Server LocalDB or SQL Server
- Domain-joined server with appropriate AD permissions
- RSAT Active Directory tools (optional, for enhanced functionality)

## Installation & Setup

### Local Development

1. **Clone the repository**
   ```bash
   cd SaveFolder/ADstatuspage
   ```

2. **Restore NuGet packages**
   ```bash
   dotnet restore
   ```

3. **Update database connection** (if not using LocalDB)
   
   Edit `appsettings.json` and modify the connection string:
   ```json
   {
     "ConnectionStrings": {
       "DefaultConnection": "Server=(localdb)\\MSSQLLocalDB;Database=ADStatusPageDb;Trusted_Connection=True;MultipleActiveResultSets=true"
     }
   }
   ```

4. **Create database and apply migrations**
   ```bash
   dotnet ef migrations add InitialCreate
   dotnet ef database update
   ```

5. **Build the project**
   ```bash
   dotnet build
   ```

6. **Run the application**
   ```bash
   dotnet run
   ```

7. **Access the application**
   
   Open your browser and navigate to `https://localhost:5001` or the URL shown in the console.

### Production Deployment to IIS

#### Step 1: Publish the Application

1. **Publish using dotnet CLI**
   ```bash
   dotnet publish -c Release -o ./publish
   ```

2. **Or publish using Visual Studio**
   - Right-click the project → Publish
   - Choose "Folder" as target
   - Select output folder and publish

#### Step 2: Prepare IIS

1. **Install required components**
   - Install the [.NET 8 Hosting Bundle](https://dotnet.microsoft.com/download/dotnet/8.0) on the server
   - Restart IIS after installation: `iisreset`

2. **Create Application Pool**
   - Open IIS Manager
   - Right-click "Application Pools" → Add Application Pool
   - Name: `ADStatusPageAppPool`
   - .NET CLR version: `No Managed Code`
   - Click OK

3. **Configure Application Pool Identity**
   - Right-click the new app pool → Advanced Settings
   - Identity: Choose one of:
     - **Option A**: `ApplicationPoolIdentity` (then grant this identity AD read permissions)
     - **Option B**: Use a domain service account with appropriate permissions
   - Idle Time-out: Increase to 0 (or higher value) if needed
   - Click OK

4. **Create Website or Application**
   - Right-click "Sites" → Add Website (or add as application under existing site)
   - Site name: `ADStatusPage`
   - Application pool: `ADStatusPageAppPool`
   - Physical path: Point to your published folder (e.g., `C:\inetpub\ADStatusPage`)
   - Binding: Configure HTTPS binding (recommended) or HTTP
   - Click OK

#### Step 3: Configure Windows Authentication

1. **In IIS Manager, select your site/application**

2. **Open "Authentication" feature**
   - Disable: Anonymous Authentication
   - Enable: Windows Authentication

3. **Configure Windows Authentication providers** (if needed)
   - Select Windows Authentication → Advanced Settings
   - Ensure providers are ordered: `Negotiate`, `NTLM`

4. **Configure authorization** (optional)
   - Create `web.config` in the published folder or use IIS Authorization Rules
   - Example `web.config` snippet:
   ```xml
   <system.webServer>
     <security>
       <authorization>
         <remove users="*" roles="" verbs="" />
         <add accessType="Allow" roles="DOMAIN\ADAdmins" />
       </authorization>
     </security>
   </system.webServer>
   ```

#### Step 4: Grant Permissions

The application pool identity must have:

1. **File System Permissions**
   - Read & Execute on the application folder
   - Full Control on `App_Data` folder (if exists)

2. **Active Directory Permissions**
   - Read access to domain objects
   - Permissions to execute `repadmin` and PowerShell AD cmdlets
   - Member of local group with necessary privileges or grant specific AD read permissions

3. **Recommended Least-Privilege Approach**
   - Create a dedicated service account (e.g., `DOMAIN\svc_ADStatusPage`)
   - Grant minimal required AD permissions:
     - Read access to Domain Controllers OU
     - Read access to Sites and Services
   - Add account to local "IIS_IUSRS" group on web server
   - If using PowerShell remoting, configure appropriate WinRM permissions

#### Step 5: Database Configuration

1. **For SQL Server LocalDB** (default)
   - Ensure LocalDB is installed on the server
   - Connection string uses integrated authentication
   - Run migrations on the server:
     ```bash
     cd C:\inetpub\ADStatusPage
     dotnet ef database update
     ```

2. **For SQL Server**
   - Update connection string in `appsettings.json`
   - Grant app pool identity or service account `db_datareader`, `db_datawriter` on the database
   - Run migrations using SQL Server credentials

## Configuration

### appsettings.json

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\MSSQLLocalDB;Database=ADStatusPageDb;Trusted_Connection=True;MultipleActiveResultSets=true"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

### Cache Configuration

Default cache expiration is 60 seconds. To modify, edit the `CacheExpirationSeconds` constant in `ADstatuspage/Services/ADHealthService.cs`:

```csharp
private const int CacheExpirationSeconds = 60; // Change as needed
```

## Troubleshooting

### PowerShell Execution Issues

**Problem**: PowerShell commands fail or timeout

**Solutions**:
1. Check PowerShell execution policy:
   ```powershell
   Get-ExecutionPolicy
   Set-ExecutionPolicy RemoteSigned -Scope LocalMachine
   ```

2. Ensure RSAT AD tools are installed:
   ```powershell
   Get-WindowsCapability -Name RSAT.ActiveDirectory* -Online | Add-WindowsCapability -Online
   ```

3. Verify WinRM is running:
   ```powershell
   Get-Service WinRM
   Start-Service WinRM
   ```

### Authentication Issues

**Problem**: 401 Unauthorized or authentication prompts

**Solutions**:
1. Verify Windows Authentication is enabled in IIS
2. Check browser is passing credentials (IE/Edge use Windows credentials automatically)
3. For Chrome/Firefox, may need to configure trusted sites
4. Ensure server is domain-joined and SPN is registered

### Permission Errors

**Problem**: Access denied when querying AD or running repadmin

**Solutions**:
1. Verify app pool identity has AD read permissions:
   ```powershell
   # Check current identity
   whoami /groups
   ```

2. Grant AD permissions using Active Directory Users and Computers:
   - Right-click domain → Delegate Control
   - Add service account
   - Grant "Read all information" permission

3. For `repadmin`, account may need to be in "Domain Admins" or have specific replication permissions

### Firewall Issues

**Problem**: Cannot connect to LDAP/LDAPS ports

**Solutions**:
1. Verify firewall rules allow outbound connections:
   - LDAP: TCP 389
   - LDAPS: TCP 636
   - DNS: UDP 53

2. Test connectivity:
   ```powershell
   Test-NetConnection -ComputerName DC01.domain.local -Port 389
   ```

### Database Migration Issues

**Problem**: Migrations fail to apply

**Solutions**:
1. Ensure LocalDB is installed:
   ```powershell
   sqllocaldb info
   ```

2. Manually apply migrations:
   ```bash
   dotnet ef database update --verbose
   ```

3. Check connection string format and permissions

### Module Not Found Errors

**Problem**: "The term 'Get-ADDomainController' is not recognized"

**Solutions**:
- The application falls back to DirectoryServices if AD PowerShell module unavailable
- Install RSAT tools for full functionality:
  ```powershell
  Install-WindowsFeature RSAT-AD-PowerShell
  ```

## Security Considerations

1. **Authentication**: Only Windows-authenticated users can access the application
2. **Authorization**: Consider restricting access to specific AD groups via IIS Authorization Rules
3. **HTTPS**: Always use HTTPS in production (configure SSL certificate in IIS)
4. **Service Account**: Use dedicated service account with minimal required permissions
5. **Credential Storage**: No credentials are stored in the application; uses Windows integrated auth
6. **Logging**: Review and secure access to `HealthCheckLog` table (contains operational data only)

## Architecture

### Project Structure

```
ADstatuspage/
├── Data/
│   ├── ApplicationDbContext.cs       # EF Core DbContext
│   └── HealthCheckLog.cs             # Logging entity
├── Services/
│   ├── IADHealthService.cs           # Service interface
│   └── ADHealthService.cs            # Health check implementation
├── Models/
│   └── HealthModels.cs               # DTOs for health data
├── Pages/
│   ├── Index.cshtml                  # Dashboard
│   ├── DomainControllers.cshtml      # DC status page
│   ├── Replication.cshtml            # Replication page
│   ├── Dns.cshtml                    # DNS health page
│   ├── Services.cshtml               # Services page
│   └── Shared/
│       └── _Layout.cshtml            # Main layout
├── wwwroot/
│   └── css/
│       └── site.css                  # Custom styles
├── appsettings.json                  # Configuration
├── Program.cs                        # Application startup
└── README.md                         # This file
```

### Key Technologies

- **ASP.NET Core 8.0**: Web framework
- **Razor Pages**: UI implementation
- **Entity Framework Core 8.0**: Database access
- **System.DirectoryServices**: AD queries
- **PowerShell SDK**: PowerShell automation
- **Windows Authentication (Negotiate)**: Security
- **In-Memory Cache**: Performance optimization

## Maintenance

### Update Checks
Regularly check for:
- .NET security updates
- NuGet package updates
- Windows Server patches

### Monitoring
- Review `HealthCheckLog` table for patterns
- Monitor IIS logs for errors
- Check Windows Event Viewer for application errors

### Backups
- Database backups (if using SQL Server)
- Configuration file backups (`appsettings.json`, `web.config`)

## License

This project is for internal use. Ensure compliance with your organization's policies.

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review application logs in `%SystemRoot%\System32\LogFiles\W3SVC1\`
3. Contact your system administrator or Active Directory team
