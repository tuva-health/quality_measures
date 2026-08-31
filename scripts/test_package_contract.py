#!/usr/bin/env python3
"""Validate package metadata and the external seed-loader contract."""

from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_DBT_REQUIREMENT = ">=1.10.5,<3.0.0"
EXPECTED_ASSET_ROOT = "data-marts/quality-measures"
EXPECTED_ASSET_VAR = "quality_measures_data_asset_version"


def extract(pattern: str, text: str, source: Path) -> str:
    match = re.search(pattern, text, flags=re.MULTILINE)
    assert match is not None, f"Expected metadata was not found in {source}"
    return match.group(1)


def main() -> None:
    project_path = ROOT / "dbt_project.yml"
    workflow_path = ROOT / ".github" / "workflows" / "create-release.yml"
    project = project_path.read_text(encoding="utf-8")
    workflow = workflow_path.read_text(encoding="utf-8")

    dbt_requirement = extract(
        r"^require-dbt-version:\s*['\"]([^'\"]+)['\"]\s*$",
        project,
        project_path,
    )
    assert dbt_requirement == EXPECTED_DBT_REQUIREMENT, (
        f"require-dbt-version must be {EXPECTED_DBT_REQUIREMENT!r}, "
        f"found {dbt_requirement!r}"
    )

    asset_version = extract(
        rf"^\s{{2}}{EXPECTED_ASSET_VAR}:\s*['\"]([^'\"]+)['\"]\s*$",
        project,
        project_path,
    )
    assert asset_version == "1.0.0", (
        f"{EXPECTED_ASSET_VAR} must start at '1.0.0', found {asset_version!r}"
    )

    loader_calls = re.findall(
        r"load_package_seed\(\s*'([^']+)'\s*,\s*([^,]+?)\s*,\s*'([^']+)'\s*\)",
        project,
        flags=re.DOTALL,
    )
    header_paths = sorted(
        f"{path.name}.gz" for path in (ROOT / "seeds").rglob("*.csv")
    )
    assert sorted(call[2] for call in loader_calls) == header_paths, (
        "every header-only seed must have one loader call"
    )
    assert all(call[0] == EXPECTED_ASSET_ROOT for call in loader_calls), (
        f"every loader call must use {EXPECTED_ASSET_ROOT!r}"
    )
    expected_var_call = f"var('{EXPECTED_ASSET_VAR}')"
    assert all(call[1].strip() == expected_var_call for call in loader_calls), (
        f"every loader call must use {expected_var_call}"
    )

    assert not (ROOT / "data_assets.yml").exists(), (
        "the cloud manifest is authoritative; do not restore data_assets.yml"
    )
    assert not (
        ROOT / "macros" / "get_quality_measures_package_version.sql"
    ).exists(), "asset versions must not be derived from the package code version"

    checkout_step = workflow.find("- uses: actions/checkout@")
    contract_command = "run: python3 scripts/test_package_contract.py"
    contract_step = workflow.find(contract_command)
    version_step = workflow.find("- name: Check version change")
    assert workflow.count(contract_command) == 1, (
        "create-release.yml must invoke the package contract exactly once"
    )
    assert -1 not in (checkout_step, contract_step, version_step), (
        "create-release.yml is missing checkout, package-contract, or version steps"
    )
    assert checkout_step < contract_step < version_step, (
        "create-release.yml must validate the package contract after checkout "
        "and before checking the code version change"
    )
    for forbidden in (
        "data_assets.yml",
        "PACKAGE_SLUG",
        "tuva-public-resources",
        "_release.json",
        "package_commit",
    ):
        assert forbidden not in workflow, (
            f"code-release workflow must not depend on data assets: {forbidden}"
        )


if __name__ == "__main__":
    main()
