** Minimal sidecar implementation with Lacework (Fargate)

This directory builds a distroless container and bundles the Lacework datacollector
along with a spawning binary that will load it along with another parameter.

Required
1. Expects an environment variable LaceworkAccessToken=API_KEY
2. Expects an environment variable RUN_CMD which is launched.

The docker-compose is provided to test locally with 2 containers which mimics
the way we deploy in ECS fargate without having to actually deploy to fargate, loading
the minimal app in ../distroless_app.
