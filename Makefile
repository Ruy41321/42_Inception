all : up

up : 
	@docker-compose -f ./srcs/docker-compose.yml -p inception up -d

down : 
	@docker-compose -f ./srcs/docker-compose.yml -p inception down

stop : 
	@docker-compose -f ./srcs/docker-compose.yml -p inception stop

start : 
	@docker-compose -f ./srcs/docker-compose.yml -p inception start

show:
	@echo ============= Containers =============
	@docker ps -a
	@echo
	@echo ============= Networks =============
	@docker network ls --filter name=inception_
	@echo
	@echo ============= Volumes =============
	@docker volume ls --filter name=inception_
	@echo

clean :
	docker stop $$(docker ps -qa); \
	docker rm $$(docker ps -qa); \
	docker rmi -f $$(docker images -qa); \
	docker volume rm $$(docker volume ls -q); \
	docker network rm $$(docker network ls -q) \
	2>/dev/null