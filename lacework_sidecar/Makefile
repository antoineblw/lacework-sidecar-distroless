all:
	docker build -t lacework-ecs-dataconnector .

test:
	docker run -e LW_CONFIG='ad22145467570f7bb1de731056224cbfad993517d08cca0ef58b3ae7' --entrypoint="/shared/bin/sh" lacework-ecs-dataconnector /shared/bin/lacework-sidecar.sh
