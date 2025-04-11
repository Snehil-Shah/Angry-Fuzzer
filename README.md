# Angry Fuzzer! (WIP)

> Continuous native fuzzing infrastructure and tooling for Go projects.

> [!NOTE]
> This is an exploratory project.

This currently implements a controller and workers. Controller's job is to find all fuzz targets in the specified repository. The controller then spawns a worker for each of the fuzz targets for the specified duration. Once done, the updated corpus is pushed to the remote repository and corresponding issue is filed in the target repository.

This is currently deployed as docker containers on a single node, orchestrated using compose for easy local testing.

## Demo:

The following video tests this on an [example target repo](https://github.com/Snehil-Shah/target) and a corresponding [corpus repo](https://github.com/Snehil-Shah/corpus) by fuzzing all packages for 30 seconds:

https://github.com/user-attachments/assets/2d3248fe-88b4-40ff-84c1-c7cdc3834688

- The automated commit: [Snehil-Shah/corpus@ad4440c](https://github.com/Snehil-Shah/corpus/commit/ad4440c2de755b23aa58e1753b9fd779e897d5bd)
- The generated issue: https://github.com/Snehil-Shah/target/issues/2

## Usage:

Add your `GITHUB_TOKEN` in `/.env`, which will be used to update the remote corpus and generate issue reports.

```bash
bash run.sh --target <repo-url> --corpus <repo-url>
```

> [!TIP]
> Powershell script also included for windows envs.

The script builds controller and worker images, and starts the controller.

> [!WARNING]
> It currently uses `tmp/angry-fuzzer` directory on the **host** machine as a persistent volume to allow concurrent access in a pseudo-docker-in-docker setup. Basically, it's not all virtualized.

## TODO:

- [X] Controller
  - Distributes packages across worker nodes. It's a coordinator service.
  - Manages metadata and other services (like telemetry, notifications etc idk).
- [X] Corpus re-integration upon fresh repo-mount (it assumes an empty corpus atm)
- [ ] Utilize da threads!
- [X] Repository management
  - Instead of writing a custom service for repo syncing and monitoring folders, write an integrated service for auto-sync (bi-directional in case of corpus repository).
  - Automated commits to corpus repository and issue filing on target.
- [ ] Do PRs instead of direct commits.
- [ ] Make sense of the fuzzing reports to make package specific issues with issue tracking.
- [ ] Additional tooling for integration with GitHub Actions, example k8s configs etc etc.
- [ ] Add more TODO.
