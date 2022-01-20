## Lacework Sidecar agent for ECS/Fargate Distroless
The purpose of this project is to build a proof of concept ECS Fargate task 
where the containers in use are google distroless images. 
More information on those containers here (https://github.com/GoogleContainerTools/distroless)

Currently Lacework's sidecar container requires and assumes that a container has a usable shell 
as it installs with a shell script and utilizes many shell tools (grep, awk, etc...). 
In the event that a customer uses a distroless OS none of these are available.

#### lacework_sidecar
The lacework_sidecar directory builds a new sidecar container which performs the following:
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

#### distroless_app
The distroless_app directory builds a tiny container with a statically compiled hello world program that runs in the distroless container.
This container has 2 apps, defaults to running one of them and defines the RUN_CMD so that the lacework container can run the command.

#### ecs
This directory contains a single task definition which calls the lacework sidecar container. 
Given we run the RUN_CMD within the lacework-sidecar script now there's no longer a need to 
run the containers app


