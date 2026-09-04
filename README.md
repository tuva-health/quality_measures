# Tuva Quality Measures

[Documentation](https://thetuvaproject.com/data-marts/quality-measures) |
[Source](https://github.com/tuva-health/quality_measures)

`quality_measures` is the standalone dbt package for Tuva's Quality Measures
data mart. It turns the standardized clinical and claims relations produced by
[Tuva Core](https://github.com/tuva-health/tuva-core) into patient-level measure
results, aggregate performance rates, and hospital-wide readmission outputs.

Installing the package is its enablement switch. It does not add a separate
`quality_measures_enabled` variable.

## What this package builds

The package currently contains two related public surfaces:

- Quality-measure results in long, wide, and aggregate-count formats. The
  implemented measures cover medication adherence, statin use and therapy,
  medication documentation, and pain assessment and follow-up.
- Hospital-wide readmission results, including encounter-level qualification
  and planned-readmission logic.

The main public relations are:

| Relation | Purpose |
| --- | --- |
| `quality_measures.summary_long` | One row per person, data source, measure, version, and performance period |
| `quality_measures.summary_wide` | Patient-level measure results in a reporting-friendly wide format |
| `quality_measures.summary_counts` | Denominator, numerator, exclusion, and performance-rate totals |
| `quality_measures.encounter_augmented` | Inpatient encounters enriched with readmission eligibility and data-quality fields |
| `quality_measures.readmission_summary` | Qualified index encounters and their subsequent readmission results |

When `tuva_schema_prefix` is configured, the default schema becomes
`<prefix>_quality_measures`.

## Prerequisites

Use this package from a connector or other root dbt project that already
installs a compatible Tuva Core release and maps source data into Tuva's Input
Layer. Do not install another copy of Core inside this package.

This release requires:

- dbt Core or Fusion `>=1.10.5,<3.0.0`
- the Tuva 1.0 Core contracts
- `claims_enabled: true` for the readmissions models
- at least one of `claims_enabled` or `clinical_enabled` for the applicable
  quality-measure models

The root project remains responsible for selecting the appropriate connector,
Core version, and claims/clinical configuration.

## Installation

Add Tuva Core and this package to the root project's `packages.yml`. Once both
releases are available on dbt Hub, a typical installation is:

```yaml
packages:
  - package: tuva-health/the_tuva_project
    version: 1.0.0
  - package: tuva-health/quality_measures
    version: 0.1.0
```

During the Tuva 1.0 prerelease window, or before a new Hub release is indexed,
pin the repositories directly instead:

```yaml
packages:
  - git: "https://github.com/tuva-health/tuva-core.git"
    revision: "<verified-tuva-core-commit-or-tag>"
  - git: "https://github.com/tuva-health/quality_measures.git"
    revision: "v0.1.0"
```

Replace the Core placeholder with a tested Tuva 1.0-compatible revision. Then
install dependencies from the root project:

```bash
dbt deps
```

## Configuration and use

Tuva Core's native boolean variables control the available input domains. For
a claims project, the root `dbt_project.yml` commonly includes:

```yaml
vars:
  claims_enabled: true
  clinical_enabled: false
```

To evaluate measures for a period ending on a date other than the current
calendar year, set:

```yaml
vars:
  quality_measures_period_end: "2025-12-31"
```

Build this package and its required upstream graph from the root project:

```bash
dbt build --select +package:quality_measures
```

Measure outputs should be reviewed against the applicable source
specifications and the intended reporting population before they are used for
external reporting.

## Package data assets

The measure definitions, value sets, and readmission reference tables are
package-owned data assets. Their compressed contents load from:

```text
data-marts/quality-measures/<asset-version>/
```

The checked-in CSV files are header-only dbt loader contracts. The default
`quality_measures_data_asset_version` is `1.0.0`; asset versions are
intentionally independent from this package's code version. Most users should
leave this value unchanged so the installed package selects its tested asset
snapshot.

## Supported warehouses

The Tuva 1.0 package set is validated on:

- Snowflake
- BigQuery
- Databricks
- Microsoft Fabric
- Redshift
- DuckDB

Adapter-specific behavior is implemented through Tuva's shared cross-database
macros. Please open an issue for reproducible behavior differences on a
supported warehouse.

## Development

Issues and pull requests are welcome in the
[GitHub repository](https://github.com/tuva-health/quality_measures). Package
models, tests, and column-level documentation live together under `models/`.
Before submitting a change, run the package contract and the narrowest useful
dbt build against a compatible Tuva Core checkout.

## License

This project is licensed under the [Apache License 2.0](LICENSE). Reference
measure specifications and terminology may have their own terms; users remain
responsible for complying with the applicable source requirements.
