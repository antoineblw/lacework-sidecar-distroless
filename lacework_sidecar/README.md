# Lacework sidecar (distroless) alpha
This module builds a sidecar container that will work in a distroless environment. This package
literally takes our existing sidecar container and tries to hack it to make it work, including the
install script.
Performs the following
- Origin (lacework/datacollector:latest-sidecar)
- Pulls a statically compiled version of busybox (x64)
- Creates a bunch of symlinks to the tools (applets) that we need in our install script.
- Copies the /lib directory to get the libraries that the Lacework datacollector depend on (primarily musl)
- Stores all the above in /shared/bin and /shared/lib
- exposes /shared as a volume so that it can be mounted elsewhere (ECS volumesFrom).
- A relatively hacked up version of the lacework launch script.
  - use /shared/bin/sh
  - copy contents of /shared/lib/ to /lib
  - removes the alpine check for which datacollector binary to run (so that we use the musl version)
  - ends by running the environment variable RUN_CMD

### docker-compose.yaml
This is meant to help local testing as opposed to pushing everything out into ECS. This mimics what
ecs fargate does in terms of loading 2 containers (lacework-sidecar, myapp), sharing a volume, 
overriding the entrypoint in myapp by launching the sidecar app (lacework-sidecar.sh). LaceworkAccessToken
needs to be set to your agent token.
