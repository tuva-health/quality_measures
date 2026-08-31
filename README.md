# Quality Measures

dbt package for the Tuva Project Quality Measures data mart.

## Data assets

Seed contents load from
`s3://tuva-public-resources/data-marts/quality-measures/<asset-version>/`.
The checked-in CSV files are header-only dbt loader contracts; their seed YAML
defines the relations, types, and tests.

`quality_measures_data_asset_version` selects the folder and defaults to
`1.0.0`. The data-asset version is intentionally independent of this package's
code version, and maintainers coordinate the two values when an asset changes.
Cloud `_manifest.json` and `_release.json` files are maintenance metadata and
are not read by dbt at runtime.
