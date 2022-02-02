## Minimal sidecar implementation with Lacework (Fargate)

This directory builds a distroless container and bundles the Lacework datacollector binary
along with a spawning binary that will load it along with another parameter.
There's a bit of a hack here in the version of the datacollector, and we include the
ld-musl-x86_64.so.1 library and manually add it to /lib within runlacework. Future iterations
will statically compile the library into datacollector.

### runlacework / runlacework.go
This will be used as the entrypoint for the lacework sidecar. This application performs the necessary
setup for the lacework data collector (path, test api access), (supposed to) parses parameters and
then launches 2 go routines. The first go routine spawns the lacework datacollector and the 
second go routine spawns the RUN_CMD as defined within the container to be tracked. Of note that RUN_CMD
is assumed to be one long string which should container program and parameters, we parse the program from
the parameters to launch the program correctly.

### docker-compose.yaml
This is meant to help local testing as opposed to pushing everything out into ECS. This mimics what
ecs fargate does in terms of loading 2 containers (lacework-sidecar, myapp), sharing a volume,
overriding the entrypoint in myapp by launching the sidecar app (runlacework). LaceworkAccessToken
needs to be set to your agent token.

### Deployment
A published version of this container is on dockerhub here *antoineblw/lacework-sidecar-nz:beta*

In order to use this in ECS/Fargate you will need to do the following:
1. In your Dockerfile for your container, define an environment variable named RUN_CMD that is the same
   as your command/entrypoint. (e.g ENV RUN_CMD "/app/app1 firstArg). Refer to distroless_app/Dockerfile for
   an example of this.
2. Define the entrypoint for your container as /lacework/runlacework
3. Add the sidecar as a non-essential container.
4. Use volumes-from to mount lacework sidecar volume to your container needing to be monitored.
5. Define LaceworkAccessToken in your enironment variables or secrets, this is your agent token

### task-definition-lw.json
You can refer to task-definition-lw.json for a sample functional ECS deployment (you'd need to tweak to
your own container)


