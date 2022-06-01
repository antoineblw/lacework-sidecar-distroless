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
  1. use /shared/bin/sh
  2. copy contents of /shared/lib/ to /lib
  3. removes the alpine check for which datacollector binary to run (so that we use the musl version)
  4. ends by running the environment variable RUN_CMD
  5. Adds /shared/bin to the env PATH

### docker-compose.yaml
This is meant to help local testing as opposed to pushing everything out into ECS. This mimics what
ecs fargate does in terms of loading 2 containers (lacework-sidecar, myapp), sharing a volume, 
overriding the entrypoint in myapp by launching the sidecar app (lacework-sidecar.sh). LaceworkAccessToken
needs to be set to your agent token.


### Deployment
A published version of this container is on dockerhub here *antoineblw/lacework-sidecar-nz:alpha*

In order to use this in ECS/Fargate you will need to do the following:
1. In your Dockerfile for your container, define an environment variable named RUN_CMD that is the same 
   as your command/entrypoint. (e.g ENV RUN_CMD "/app/app1 firstArg). Refer to distroless_app/Dockerfile for
   an example of this.
2. Your PATH must include /shared/bin
3. Define the entrypoint for your container as /shared/bin/sh /shared/bin/lacework-sidecar.sh
4. Add the sidecar as a non-essential container.
5. Use volumes-from to mount lacework sidecar volume to your container needing to be monitored.
6. Define LaceworkAccessToken in your enironment variables or secrets, this is your agent token

### task-definition-lw.json
You can refer to task-definition-lw.json for a sample functional ECS deployment (you'd need to tweak to
your own container) 
