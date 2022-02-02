## Lacework Sidecar agent for ECS/Fargate Distroless
The purpose of this project is to build a proof of concept ECS Fargate task 
where the containers in use are google distroless images. 
More information on those containers here (https://github.com/GoogleContainerTools/distroless)

Currently Lacework's sidecar container requires and assumes that a container has a usable shell 
as it installs with a shell script and utilizes many shell tools (grep, awk, etc...). 
In the event that a customer uses a distroless OS none of these are available.

#### lacework_sidecar_alpha
  First iteration of distroless support. This iteration uses the production lacework sidecar container
  as a baseline and makes modifications to shoehorn in busybox to support the deployment of Lacework.


#### lacework_sidecar_beta
  Second iteration of distroless support. This iteration builds a static go binary which will launch both
  the datacollector and the app to be monitored within 2 go routines. This achieves a deployment without
  introucing busybox.


#### distroless_app
  The distroless_app directory builds a tiny container with a statically compiled hello world 
  program that is then run within a distroless container. (named myapp)
  The Dockerfile defines both CMD and RUN_CMD. RUN_CMD is what will be used by the lacework-sidecar

