# PowerShell Administration Scripts

A collection of PowerShell scripts for Windows administration, Microsoft cloud services, infrastructure operations, troubleshooting, and cross-platform system management.

The repository currently contains 250 standalone scripts. It is a script library rather than a single PowerShell module, so each script has its own purpose, parameters, prerequisites, and platform requirements.

## Script categories

| Location | Scripts | What they cover |
| --- | ---: | --- |
| [`ActiveDirectory/`](ActiveDirectory/) | 61 | Users and groups, passwords, domain controllers, replication, sites and subnets, OUs, Group Policy, FSMO roles, ADMT preparation, and domain migrations. |
| [`CertManagement/`](CertManagement/) | 15 | Certificate discovery, expiration reporting and cleanup, certificate requests, imports and exports, and self-signed certificates on Windows, Linux, and macOS. |
| [`DNS/`](DNS/) | 8 | DNS registration and cache operations, zone exports, stale or domain-controller record cleanup, Azure DNS CAA records, and DNS application load-balancing records. |
| [`HyperV/`](HyperV/) | 4 | Hyper-V virtual-machine creation, network adapters, snapshots, and Windows Server 2025 VM provisioning. |
| [`M365/`](M365/) | 18 | Microsoft Graph, Exchange Online, SharePoint Online, Purview, licensing, mailbox auditing and rules, email, recycle-bin cleanup, and Microsoft 365 removal utilities. |
| [`MultiOS/`](MultiOS/) | 19 | Cross-platform inventory, networking, DNS, processes, services, disk information, reboots, cleanup, VPN connectivity, and hardware audits for Windows, Linux, and macOS. |
| [`Sharepoint/`](Sharepoint/) | 2 | SharePoint user and group membership reporting. |
| [`WindowsUpdate/`](WindowsUpdate/) | 7 | Update history, hotfix searches, patch installation, Windows Update enable/disable operations, and component reset. |
| Repository root | 116 | General Windows, PowerShell, networking, system, file, database, and remote-administration utilities. |

### General utilities in the repository root

The root-level scripts cover several broader areas:

- **System configuration and security** — Windows features, Server hardening, TLS, BitLocker, UAC, firewalls, RDP, NTP, product keys, disk resizing, and unattended Windows Server setup.
- **Inventory and diagnostics** — Computer, BIOS, motherboard, driver, software, service, event-log, stability, SQL Server, database-backup, and resource-usage information.
- **Networking and remote management** — IPv4/IPv6 renewal, ARP, DHCP, bandwidth tests, WinRM, PowerShell remoting, SSH configuration, remote file copies, and remote computer maintenance.
- **Services and processes** — Service start/stop and reporting, process discovery and termination, reboot tools, and remote cleanup.
- **PowerShell setup and maintenance** — PowerShell installation and configuration, repository and module management, aliases, profiles, context-menu integration, and PSScriptAnalyzer.
- **Files and data** — CSV comparison and export, text and XML file creation, batch renaming, duplicate-file hashing, ownership changes, and directory reports.
- **Messaging and databases** — SMTP email utilities, SQL Server discovery and backup checks, and Oracle remediation helpers.

## Requirements and compatibility

Requirements vary by script:

- Most Windows administration scripts are intended for Windows PowerShell 5.1 or PowerShell 7 and may require an elevated session.
- Scripts in [`MultiOS/`](MultiOS/) generally use PowerShell 7 for Windows, Linux, and macOS support.
- Some scripts require Windows roles or tools such as Active Directory Domain Services, DNS Server, Hyper-V, RSAT, or SQL Server tooling.
- Microsoft 365 scripts may require modules such as Microsoft Graph, ExchangeOnlineManagement, PnP.PowerShell, or PartnerCenter, along with the appropriate tenant permissions.
- Certificate scripts for Linux or macOS may rely on native tools such as `openssl` or `security`.

Review the comment-based help and source of an individual script before running it. Compatibility is documented per script where available.

## Getting started

Clone the repository:

```powershell
git clone https://github.com/ryroeu/powershell.git
Set-Location ./powershell
```

Inspect a script's help before using it:

```powershell
Get-Help ./GetComputerInfo.ps1 -Full
```

Run a script from the repository directory:

```powershell
./GetComputerInfo.ps1
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
