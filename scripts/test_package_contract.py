#!/usr/bin/env python3
"""Validate package metadata that must move together for a release."""

from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_DBT_REQUIREMENT = ">=1.10.5,<3.0.0"
EXPECTED_ASSET_SLUG = "quality-measures"
EXPECTED_VERSION_CALL = "quality_measures.get_quality_measures_package_version()"


def extract(pattern: str, text: str, source: Path) -> str:
    match = re.search(pattern, text, flags=re.MULTILINE)
    assert match is not None, f"Expected metadata was not found in {source}"
    return match.group(1)


def main() -> None:
    project_path = ROOT / "dbt_project.yml"
    macro_path = ROOT / "macros" / "get_quality_measures_package_version.sql"
    assets_path = ROOT / "data_assets.yml"
    workflow_path = ROOT / ".github" / "workflows" / "create-release.yml"

    project = project_path.read_text(encoding="utf-8")
    macro = macro_path.read_text(encoding="utf-8")
    assets = assets_path.read_text(encoding="utf-8")
    workflow = workflow_path.read_text(encoding="utf-8")

    project_version = extract(
        r"^version:\s*['\"]?([^'\"\s#]+)['\"]?\s*$", project, project_path
    )
    macro_version = extract(
        r"\breturn\(\s*['\"]([^'\"]+)['\"]\s*\)", macro, macro_path
    )
    dbt_requirement = extract(
        r"^require-dbt-version:\s*['\"]([^'\"]+)['\"]\s*$",
        project,
        project_path,
    )
    asset_slug = extract(r"^package:\s*([^\s#]+)\s*$", assets, assets_path)

    assert project_version == macro_version, (
        f"dbt_project.yml version {project_version!r} does not match "
        f"the package macro version {macro_version!r}"
    )
    assert dbt_requirement == EXPECTED_DBT_REQUIREMENT, (
        f"require-dbt-version must be {EXPECTED_DBT_REQUIREMENT!r}, "
        f"found {dbt_requirement!r}"
    )
    assert asset_slug == EXPECTED_ASSET_SLUG, (
        f"data_assets.yml package must remain {EXPECTED_ASSET_SLUG!r}, "
        f"found {asset_slug!r}"
    )
    loader_calls = re.findall(
        r"load_package_seed\(\s*'([^']+)'\s*,\s*([^,]+?)\s*,\s*'([^']+)'\s*\)",
        project,
        flags=re.DOTALL,
    )
    catalog_paths = re.findall(r"^    path:\s*(\S+)\s*$", assets, re.MULTILINE)
    assert sorted(call[2] for call in loader_calls) == sorted(catalog_paths), (
        "every catalog asset must have one loader call"
    )
    assert all(call[0] == EXPECTED_ASSET_SLUG for call in loader_calls), (
        "every loader call must use the stable asset slug"
    )
    assert all(call[1].strip() == EXPECTED_VERSION_CALL for call in loader_calls), (
        "every loader call must use the namespaced package-version macro"
    )

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
        "and before checking the version change"
    )


if __name__ == "__main__":
    main()
