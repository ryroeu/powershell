# PowerShell Administration Scripts

A collection of PowerShell scripts for Windows administration, Microsoft cloud services, infrastructure operations, troubleshooting, and cross-platform system management.

The repository currently contains 250 standalone scripts. It is a script library rather than a single PowerShell module, so each script has its own purpose, parameters, prerequisites, and platform requirements.

## Script categories

| Location | Scripts | What they cover |
| --- | ---: | --- |
| [`ActiveDirectory/`](ActiveDirectory/) | 61 | Users and groups, passwords, domain controllers, replication, sites and subnets, OUs, Group Policy, FSMO roles, ADMT preparation, and domain migrations. |
| [`CertManagement/`](CertManagement/) | 15 | Certificate discovery, expiration reporting and cleanup, certificate requests, imports and exports, and self-signed certificates on Windows, Linux, and macOS. |
| [`Database/`](Database/) | 3 | SQL Server instance, database, and backup discovery. |
| [`DeploymentLicensing/`](DeploymentLicensing/) | 4 | Windows unattended deployment media, KMS activation, and local or remote product-key management. |
| [`DHCP/`](DHCP/) | 3 | DHCP Server installation, configuration, lease reporting, and XML exports. |
| [`DNS/`](DNS/) | 8 | DNS registration and cache operations, zone exports, stale or domain-controller record cleanup, Azure DNS CAA records, and DNS application load-balancing records. |
| [`FileManagement/`](FileManagement/) | 14 | Text, XML, and CSV operations; directory reports; duplicate detection; batch renaming; and file ownership. |
| [`HyperV/`](HyperV/) | 4 | Hyper-V virtual-machine creation, network adapters, snapshots, and Windows Server 2025 VM provisioning. |
| [`M365/`](M365/) | 18 | Microsoft Graph, Exchange Online, SharePoint Online, Purview, licensing, mailbox auditing and rules, email, recycle-bin cleanup, and Microsoft 365 removal utilities. |
| [`MonitoringDiagnostics/`](MonitoringDiagnostics/) | 7 | Event logs, reliability data, disk-space alerts, HTTP checks, CHKDSK results, and SMTP notifications. |
| [`MultiOS/`](MultiOS/) | 19 | Cross-platform inventory, networking, DNS, processes, services, disk information, reboots, cleanup, VPN connectivity, and hardware audits for Windows, Linux, and macOS. |
| [`Networking/`](Networking/) | 12 | Address and adapter configuration, ARP, IPv4 and IPv6 lease operations, bandwidth measurement, geolocation, and TCP utilities. |
| [`PowerShell/`](PowerShell/) | 14 | PowerShell installation, modules, repositories, environment configuration, console customization, and reusable examples. |
| [`RemoteManagement/`](RemoteManagement/) | 15 | WinRM, PowerShell remoting, SSH, RDP, remote file transfer, remote maintenance, and client/server remoting configuration. |
| [`SecurityHardening/`](SecurityHardening/) | 8 | BitLocker, UAC, TLS, Windows Firewall, CredSSP policy, and server-hardening configuration. |
| [`ServicesProcesses/`](ServicesProcesses/) | 9 | Service and process discovery, reporting, resource monitoring, start, stop, and termination operations. |
| [`Sharepoint/`](Sharepoint/) | 2 | SharePoint user and group membership reporting. |
| [`SystemConfiguration/`](SystemConfiguration/) | 9 | Registry inspection, storage and hibernation configuration, WMI repair, NTP, reboot, and local computer settings. |
| [`SystemInventory/`](SystemInventory/) | 6 | Computer, BIOS, motherboard, driver, and installed-software inventory. |
| [`UserManagement/`](UserManagement/) | 5 | Local administrators, user profiles, shell-folder redirection, and logged-on session discovery. |
| [`WindowsFeatures/`](WindowsFeatures/) | 6 | Windows Server role and feature discovery, installation, and removal, including RSAT and File Services. |
| [`WindowsUpdate/`](WindowsUpdate/) | 7 | Update history, hotfix searches, patch installation, Windows Update enable/disable operations, and component reset. |
| Repository root | 1 | Repository-wide PSScriptAnalyzer entry point and its settings file. |

### Repository organization

Scripts are grouped by administrative purpose rather than only by operating system or execution method. The repository root is reserved for documentation, repository configuration, and the repository-wide `PSScriptAnalyzer.ps1` entry point. Companion data files, such as `Networking/GeoLocate.json`, are stored beside the scripts that consume them.

## Requirements and compatibility

Requirements vary by script:

- The repository is maintained and validated against the current PowerShell 7 LTS release (PowerShell 7.6.3 at the time of this audit).
- Windows administration scripts may require an elevated session and Windows-only modules, roles, or compatibility components.
- Scripts in [`MultiOS/`](MultiOS/) use PowerShell 7 for Windows, Linux, and macOS support.
- Some scripts require Windows roles or tools such as Active Directory Domain Services, DNS Server, Hyper-V, RSAT, or SQL Server tooling.
- Microsoft 365 scripts may require modules such as Microsoft Graph, ExchangeOnlineManagement, PnP.PowerShell, or PartnerCenter, along with the appropriate tenant permissions.
- Certificate scripts for Linux or macOS may rely on native tools such as `openssl` or `security`.

Review the comment-based help and source of an individual script before running it. Compatibility is documented per script where available.

## Repository validation

Install the current PSScriptAnalyzer release, then run the repository checks from its root:

```powershell
Install-PSResource PSScriptAnalyzer -Scope CurrentUser

# Syntax: parse every script without executing it.
$parseErrors = Get-ChildItem -Recurse -Filter *.ps1 | ForEach-Object {
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $_.FullName,
        [ref]$tokens,
        [ref]$errors
    )
    $errors
}
if ($parseErrors) { $parseErrors; throw 'PowerShell parser validation failed.' }

# Correctness and style rules for this script collection.
Invoke-ScriptAnalyzer -Path . -Recurse -Settings ./PSScriptAnalyzerSettings.psd1

# Formatting check (reports files whose current text differs from Invoke-Formatter output).
Get-ChildItem -Recurse -Filter *.ps1 | Where-Object {
    $content = Get-Content -LiteralPath $_.FullName -Raw
    (Invoke-Formatter -ScriptDefinition $content) -cne $content
}
```

## Getting started

Clone the repository:

```powershell
git clone https://github.com/ryroeu/powershell.git
Set-Location ./powershell
```

Inspect a script's help before using it:

```powershell
Get-Help ./SystemInventory/GetComputerInfo.ps1 -Full
```

Run a script from the repository directory:

```powershell
./SystemInventory/GetComputerInfo.ps1
```

On Linux or macOS, invoke cross-platform scripts with `pwsh` when necessary:

```powershell
pwsh ./MultiOS/GetSysInfo.ps1
```

## Important safety notice

Many scripts can change operating-system, directory-service, network, certificate, or cloud-tenant configuration. Before using a script in production:

1. Read the complete script and verify its parameters and prerequisites.
2. Test it in a non-production environment.
3. Use the least-privileged account appropriate for the task.
4. Use `-WhatIf` when the script supports it.
5. Back up relevant systems or configuration before destructive operations.

Do not store passwords, access tokens, private keys, certificates, tenant identifiers, or other secrets in scripts or commit them to the repository.
