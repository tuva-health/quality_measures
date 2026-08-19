# Quality Measures

dbt package for the Tuva Project Quality Measures data mart.

## Data assets

Released seed contents are stored as an immutable snapshot under
`s3://tuva-public-resources/quality-measures/<package-version>/`. The
checked-in CSV files define the dbt loader headers, and `data_assets.yml` is
the publisher inventory. Dataset changes are released with a new package
version.

On a version-changing push to `main`, or a manual recovery from current
`main`, release automation verifies the exact, commit-bound, byte-identical
`_release.json` receipt in S3, GCS, and Azure before creating the
`v<package-version>` tag and draft GitHub release.
