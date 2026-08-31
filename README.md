# Quality Measures

dbt package for the Tuva Project Quality Measures data mart.

## Data assets

Released seed contents are stored as an immutable snapshot under
`s3://tuva-public-resources/quality-measures/<package-version>/`. The
checked-in CSV files define the dbt loader headers, and `data_assets.yml` is
the publisher inventory. Dataset changes are released with a new package
version.

On a version-changing push to `main`, or a manual recovery from current
`main`, release automation verifies that every path in `data_assets.yml`
exists under the package-version folder in S3, GCS, and Azure before creating
the `v<package-version>` tag and draft GitHub release. Each package version
maps directly to its public data-asset folder.
