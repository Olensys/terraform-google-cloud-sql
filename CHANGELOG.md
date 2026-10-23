# Changelog

## 1.0.1

### Fixes

- pin ENTERPRISE edition on the mysql instance
- expose provider-reported ip_configuration without sensitive marking
- declare and mock google-beta, pin edition ENTERPRISE, scope trivy ignores inline, add HA/PITR precondition

## 1.0.0

- Cloud SQL (postgres or mysql) with private IP only, enforced TLS, backups with PITR, HA by default in prod, query insights, and generated user passwords stored in Secret Manager.
