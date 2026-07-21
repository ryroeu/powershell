# Security Policy

## Supported Versions

This repository contains standalone PowerShell scripts and does not currently
publish versioned releases.

| Version | Supported |
| ------- | --------- |
| Latest commit on `master` | ✅ |
| Older commits, copies, and forks | ❌ |

Security fixes will be applied to the latest version on the `master` branch.

## Reporting a Vulnerability

Please do not report security vulnerabilities through a public GitHub issue.

Instead, report them privately using
[GitHub Private Vulnerability Reporting](https://github.com/ryroeu/powershell/security/advisories/new).

Please include:

- The affected script and relevant line numbers
- A description of the vulnerability and its potential impact
- Steps to reproduce the issue
- Your PowerShell version and operating system
- Any suggested remediation, if available

You can expect an acknowledgement within seven days. Confirmed vulnerabilities
will be investigated, and updates will be provided as remediation progresses.
Please allow time for a fix before publicly disclosing the issue.

## Security Considerations

Some scripts in this repository perform administrative or system-level
operations. Review scripts before running them, test them in a safe environment,
and use the least-privileged account appropriate for the task.

Never commit credentials, access tokens, private keys, certificates, or other
sensitive information to this repository.
