GO=/home/antoineb/Downloads/go/bin/go

laceworkcompile:
	CGO_ENABLED=0 $(GO) build -o runlacework -a -ldflags '-extldflags "-static"' runlacework.go

build-container:
	docker build -t lacework-ecs-datacollector-static .

clean:
	rm runlacework

aws:
	docker tag lacework-ecs-datacollector-static 613680581058.dkr.ecr.us-east-1.amazonaws.com/lacework-ecs-dataconnector:nz
	docker push 613680581058.dkr.ecr.us-east-1.amazonaws.com/lacework-ecs-dataconnector:nz


all: laceworkcompile build-container
