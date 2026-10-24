# Changelog

## [1.1.1](https://github.com/Olensys/terraform-google-cloud-sql/compare/v1.1.0...v1.1.1) (2026-10-24)


### Bug Fixes

* **examples:** use the smallest shapes for the integration apply ([55453cd](https://github.com/Olensys/terraform-google-cloud-sql/commit/55453cdd2a44bfc46fb4edb33d481cd27aaf69e7))
* run integration on change and weekly instead of nightly ([6af9d79](https://github.com/Olensys/terraform-google-cloud-sql/commit/6af9d79a4759914dd8100b6f683ec45039f02798))

## 1.1.0

### Fixes

- normalise `context.extra_tags` keys and values to valid GCP label syntax (lowercase, `[^a-z0-9_-]` replaced by `-`, 63 characters); `labels` are applied verbatim and win

### Tests

- `test_tags_contract` now covers mixed-case extra tags and verifies normalisation

### Docs

- Usage shows the naming module; Opinions describe label normalisation

### Behaviour changes

- `labels` output and applied labels now contain normalised keys and values for `context.extra_tags` (for example `Team = "Core Team"` becomes `team = "core-team"`). Callers that relied on mixed-case or space-containing extra tags must expect the normalised form; values passed in `labels` are unchanged.

## 1.0.1

### Fixes

- pin ENTERPRISE edition on the mysql instance
- expose provider-reported ip_configuration without sensitive marking
- declare and mock google-beta, pin edition ENTERPRISE, scope trivy ignores inline, add HA/PITR precondition

## 1.0.0

- Cloud SQL (postgres or mysql) with private IP only, enforced TLS, backups with PITR, HA by default in prod, query insights, and generated user passwords stored in Secret Manager.
