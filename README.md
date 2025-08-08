# github-actions-workflows

This repo features various [**reusable**](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows)
(i.t. to be called by another workflow) GitHub Actions workflows intended to be used by other code (Rust/Java) repos 
in this GitHub organization.

The following [workflow_call](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_call) workflows are available out-of-the-box:

| Name                     | YAML                                                              | Required<br> [permissions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#permissions) | Description                                                                                                                          | Artifacts <br>(produced during runtime) |
|--------------------------|-------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------|:---------------------------------------:|
| rust-clippy analyze      | [`rust-clippy.yml`](.github/workflows/rust-clippy.yml)            | `actions: read`, <br>`security-events: write`, <br>`contents: read`                                                        | Checks Rust package to catch common mistakes and improve the code                                                                    |                   :x:                   |
| OSV-Scanner              | [`osv-scanner.yml`](.github/workflows/rust-osv-scanner.yml)       | `actions: read`, <br>`security-events: write`, <br>`contents: read`                                                        | Run OSV (vulnerabilities) scanner                                                                                                    |           :white_check_mark:            |
| Build and test Rust code | [`build-and-test.yml`](.github/workflows/rust-build-and-test.yml) | `contents: read`                                                                                                           | Compile a local package and all of its dependencies and execute all unit and integration tests and build examples of a local package |                   :x:                   |

## Workflows

### `rust-clippy.yml`

```mermaid
sequenceDiagram
    autonumber

    actor dev as Developer
    participant gh as GitHub
    participant rust   as rust-toolchain@linux
    participant CodeQL as CodeQL

    %%Note over dev,CodeQL: The user must be logged in
    Note right of dev: A logged in GitHub user<br> with sufficient access right
    %%Note right of rust: Container
    Note right of CodeQL: ⚠️ MUST be activated in<br> Settings -> Advanced Security -> Code scanning

    dev    ->>+ gh: push local commits to remote<br>(git commit -am ... && git push)
    gh     ->>- rust: run Clippy<br>⚠️ Only in case any of **/*rs files changed
    rust   ->>  rust: convert Clippy output<br> into a SARIF format
    rust   ->>+ CodeQL: upload the SARIF file
    CodeQL ->>  CodeQL: scan the SARIF file<br> against vulnerabilities

    alt Vunerabilities detected
        CodeQL ->>- gh: raise alerts based on the vulnerabilities report<br> (browsable via Security -> Code scanning)
        gh     -->> dev: notify user<br> ⚠️ Only if Watch "Security alerts" option activated:<br> Send an email notification<br> featuring a detailed report<br> on all new security issues
    end
```

### `osv-scanner.yml`

```mermaid
sequenceDiagram
    autonumber

    actor dev as Developer
    participant gh as GitHub
    participant rust   as rust-toolchain@linux
    participant osv    as OSV<br> (vulnerabilities)<br> scanner
    participant CodeQL as CodeQL

    %%Note over dev,CodeQL: The user must be logged in
    Note right of dev: A logged in GitHub user<br> with sufficient access right
    %%Note right of rust: Container
    Note right of CodeQL: ⚠️ MUST be activated in<br> Settings -> Advanced Security -> Code scanning

    dev    ->>+ gh: push local commits to remote<br>(git commit -am ... && git push)
    gh     ->>+ rust: create SBOM file from Cargo.toml<br>⚠️ Only in case any of **/Cargo.toml file(s) changed
    rust   ->>- gh: upload the SBOM file
    osv    ->>+ gh: download the SBOM file
    osv    ->>+ osv: Scan against<br> vulnerabilities DB
    osv    ->>+ CodeQL: upload the SARIF file
    CodeQL ->>  CodeQL: scan the SARIF file<br> against vulnerabilities

    alt Vunerabilities detected
        CodeQL ->>- gh: raise alerts based on the vulnerabilities report<br> (browsable via Security -> Code scanning)
        gh     -->> dev: notify user<br> ⚠️ Only if Watch "Security alerts" option activated:<br> Send an email notification<br> featuring a detailed report<br> on all new security issues
    end
```



## (Re)usage examples

### `rust-clippy.yml`

```yaml
on:
  push:
    #branches: [ "main" ]
    # speed up the CI pipeline, since the linting process will not be performed if no source code files were changed.
    paths:
      - '**/*.rs'

permissions:
  # Required to upload SARIF file to CodeQL. See: https://github.com/github/codeql-action/issues/2117
  actions: read
  # Require writing security events to upload SARIF file to security tab
  security-events: write
  # to fetch code (actions/checkout)
  contents: read

jobs:
  rust-clippy:
    uses: swiyu-admin-ch/github-actions-workflows/.github/workflows/rust-clippy.yml@main
```

### `osv-scanner.yml`

```yaml
on:
  push:
    #branches: [ "main" ]
    # speed up the CI pipeline, since the audit process will not be performed if no dependencies were changed.
    paths:
      - '**/Cargo.toml'

permissions:
  # Required to upload SARIF file to CodeQL. See: https://github.com/github/codeql-action/issues/2117
  actions: read
  # Require writing security events to upload SARIF file to security tab
  security-events: write
  # to fetch code (actions/checkout)
  contents: read

jobs:
  rust-osv-scanner:
    uses: swiyu-admin-ch/github-actions-workflows/.github/workflows/rust-osv-scanner.yml@main
```
