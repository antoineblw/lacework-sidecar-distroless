container:
	docker pull lacework/datacollector:latest-sidecar
	docker build -t lacework-ecs-datacollector-alpha .

aws:
	docker tag lacework-ecs-datacollector-alpha 613680581058.dkr.ecr.us-east-1.amazonaws.com/lacework-ecs-dataconnector:nz_alpha
	docker push 613680581058.dkr.ecr.us-east-1.amazonaws.com/lacework-ecs-dataconnector:nz_alpha

dockerhub:
	docker tag lacework-ecs-datacollector-alpha antoineblw/lacework-sidecar-nz:alpha
	docker push antoineblw/lacework-sidecar-nz:alpha

task:
	aws ecs register-task-definition --cli-input-json file://./task-definition-lw.json
task-dh:
	aws ecs register-task-definition --cli-input-json file://./task-definition-lw-alpha-dockerhub.json

login:
	aws ecr get-login-password --region us-east-1 | \
        docker login --username AWS --password-stdin \
          613680581058.dkr.ecr.us-east-1.amazonaws.com/antoine_elastic_registry


all: build-container

