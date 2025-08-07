# workflows

This configuration directory containing various YAML files describing GitHub Actions workflows,
as advised [here](https://docs.github.com/en/actions/get-started/understanding-github-actions#workflows):

_A workflow is a configurable automated process that will run one or more jobs.
Workflows are defined by a YAML file checked in to your repository and will run when triggered by an event in your repository,
or they can be triggered manually, or at a defined schedule._

This repo features the following workflows:

| Name                | YAML                                       |                                                                                                              [Triggering <br>event](https://docs.github.com/en/actions/reference/events-that-trigger-workflows)                                                                                                               | Description                                                                                                                          | Artifacts <br>(produced during runtime) |
|---------------------|--------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|--------------------------------------------------------------------------------------------------------------------------------------|:---------------------------------------:|
| rust-clippy analyze | [`rust-clippy.yml`](rust-clippy.yml)       |                                                               [push](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#push), [pull_request](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#pull_request)                                                                | Run rust-clippy analyzing                                                                                                            |                   :x:                   |
| OSV-Scanner         | [`osv-scanner.yml`](osv-scanner.yml)       | [push](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#push), [pull_request](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#pull_request), [merge_group](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#merge_group) | Run OSV (vulnerabilities) scanner                                                                                                    |           :white_check_mark:            |
| Build and test      | [`build-and-test.yml`](build-and-test.yml) |                                                                                                                    [push](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#push)                                                                                                                    | Compile a local package and all of its dependencies and execute all unit and integration tests and build examples of a local package |           :white_check_mark:            |

