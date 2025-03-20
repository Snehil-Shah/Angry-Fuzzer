# Angry Fuzzer! (WIP)

> Continuous native fuzzing infrastructure and tooling for Go projects.

> [!NOTE]
> This is an exploratory project.

This currently implements a controller and workers. Controller's job is to find all fuzz targets in the specified repository. The controller then spawns a worker for each of the fuzz targets for the specified duration. Once done, the corpus folder is updated locally. Ideally, it should be synced back to the remote (TODO).

This is currently deployed as docker containers on a single node, orchestrated using compose for easy local testing.

## Usage:

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
- [ ] Corpus re-integration upon fresh repo-mount (it assumes an empty corpus atm)
- [ ] Utilize da threads!
- [ ] Repository management
  - Instead of writing a custom service for repo syncing and monitoring folders, write an integrated service for auto-sync (bi-directional in case of corpus repository).
  - Automated PRs to corpus repository and issue filing on target.
- [ ] Additional tooling for integration with GitHub Actions, example k8s configs etc etc.
- [ ] Add more TODO.