GO=/home/antoineb/Downloads/go/bin/go

laceworkcompile:
	CGO_ENABLED=0 $(GO) build -o runlacework -a -ldflags '-extldflags "-static"' runlacework.go

build-container:
	docker pull lacework/datacollector:latest-sidecar
	docker build -t lacework-ecs-datacollector-static .

clean:
	rm runlacework

aws:
	docker tag lacework-ecs-datacollector-static 613680581058.dkr.ecr.us-east-1.amazonaws.com/lacework-ecs-dataconnector:nz
	docker push 613680581058.dkr.ecr.us-east-1.amazonaws.com/lacework-ecs-dataconnector:nz

dockerhub:
	docker tag lacework-ecs-datacollector-static antoineblw/lacework-sidecar-nz:beta
	docker push antoineblw/lacework-sidecar-nz:beta

task:
	aws ecs register-task-definition --cli-input-json file://./task-definition-lw.json

all: laceworkcompile build-container
