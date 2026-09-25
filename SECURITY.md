# Security Policy

## Supported versions

The latest `0.1.x` release is the supported version.

## Reporting a vulnerability

If you believe you have found a security issue in FlutterGuard:

1. Do **not** open a public issue.
2. Use the repository's private security advisory flow once a public
   repository URL is published.
3. Include the package version, a minimal reproduction, and the impact.

Do not attach real access tokens, refresh tokens, passwords, or production
data to a report.

## Handling guidance

FlutterGuard redacts common secret field names before they are stored in the
in-memory logger. The debug inspector is disabled by the production
environment preset and by release-mode defaults.

The default token store is in-memory. Production applications must inject a
secure `TokenStore`. The default key-value store is also in-memory. Do not
persist tokens or personal data to an unencrypted file store.
