# Angry Fuzzer! (WIP)

> Continuous native fuzzing infrastructure and tooling for Go projects.

**Note**: This is an exploratory project.

This currently implements a worker node that runs fuzzing for all packages in the target.

## TODO:

- [ ] Controller
  - Distributes packages across worker nodes. It's a coordinator service.
  - Manages metadata and other services (like telemetry, notifications etc idk).
- [ ] Utilize da threads!
- [ ] Repository management
  - Instead of writing a custom service for repo syncing and monitoring folders, write an integrated service for auto-sync (bi-directional in case of corpus repository).
  - Automated PRs to corpus repository and issue filing on target.
- [ ] Additional tooling for integration with GitHub Actions, example k8s configs etc etc.
- [ ] Add more TODO.