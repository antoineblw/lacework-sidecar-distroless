all:
	docker build -t myapp .
	docker tag myapp 613680581058.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
	docker push 613680581058.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
