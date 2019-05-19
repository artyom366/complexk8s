#=====Basic

#run container
$ docker run hello-world 	

#run container {-d} release the console
$ docker run -d redis			

#create container and some container "id" returns
$ docker create hello-world 			
$ 05cecd940aa1919626ec3872ab99618b8903f49a9ae81889449df1c6dd427615 

#start container by returned "id" previously
#optional parameter -a outputs the container logs to console (attaches container to a console)
$ docker start {-a} 05cecd940aa1919626ec3872ab99618b8903f49a9ae81889449df1c6dd427615 	

#list running containers
$ docker ps

#list all running and previously run containers
$ docker ps --all

#clear list of stopped containers
$ docker system prune

#prints out container emitted logs without rerunning the container 
$ docker logs 05cecd940aa1919626ec3872ab99618b8903f49a9ae81889449df1c6dd427615 

#stops the container
$docker stop 05cecd940aa1919626ec3872ab99618b8903f49a9ae81889449df1c6dd427615 

#kills the container
$ docker kill 05cecd940aa1919626ec3872ab99618b8903f49a9ae81889449df1c6dd427615 

#execute a command on already running container (parameter -it stands for input)
$ docker exec -it 05cecd940aa1919626ec3872ab99618b8903f49a9ae81889449df1c6dd427615 {command}

#start running container shell
$ docker exec -it 05cecd940aa1919626ec3872ab99618b8903f49a9ae81889449df1c6dd427615 sh

#run container with shell instead of main or default process, {-it standart in connected}
$ docker run -it busybox sh

#run docker container with port forwarding
$ docker run -p 3000:3000 5bb155a45168

#attach console to a docker container
$ docker attach 05cecd940aa19

#run docker container with port forwarding and volume mapping
#{-v /app/node_modules} map only container node_modules directory making it a placeholder and exclude from mapping as it might not be present on local machine
#{$(pwd):/app} reference everything from present working directory to /app 
$ docker run -p 3000:3000 -v /app/node_modules -v $(pwd):/app 5bb155a45168

#=====Dockerfile

# Use an existing docker image as a base
FROM alpine

# Setup docker image current working directory
WORKDIR /usr.app

# Download everything from current directory to docker image relative to the current working directory 
COPY ./ ./

# Download and install a dependencies
RUN apk add --update redis

# Tell the image what to do when it starts as container
CMD ["redis-server"]

#build new image from Dockerfile (run from the location of Dockerfile)
$ docker build .

#build new image from specific Dockerfile {-f file path}
$ docker build -f Dockerfile.def .

#build new image from specific Dockerfile {-f file path}
$ docker build -t artyom366/docker-react -f Dockerfile.def .

#build new image with a tag
$ docker build -t artyom366/redis:latest .
$ docker run artyom366/redis

#tag an existing image
$ docker tag 0e5574283393 fedora/httpd:version1.0

#=====Multi step Dockerfile

FROM node:alpine as builder #phase name
WORKDIR /app
COPY package.json .
RUN npm install
COPY . . 
RUN npm run build

FROM nginx
EXPOSE 80	#informational only, does nothing
COPY --from=builder /app/build /usr/share/nginx/html #use the phase name to get the {npm run build} files result and copy to nginx server directory 

#commit changes on running container to create new image (parameter -c stands for set up the container run command) some other image id returns
$ docker commit -c 'CMD ["redis-server"]' 05cecd940aa1919626ec3872ab99618b8903f49a9ae81889449df1c6dd427615
$ 618b8903f49a9ae81889449df...

#======docker-compose.yml
version: '3'			#compose version
services: 				#container services
  redis-server:			#redis container name
    image: 'redis'		#use image 'redis'
  node-app:				#web application container name
    restart: 'no'/always/on-failure/unless-stopped		#restart container policy
    build: .			#buils from Dockerfile in the same directory
    ports:				#with port forwarding
      - "4001:8081"  
	  
#start executing docker-compose.yml script in the current directory
$ docker-compose up

#start executing docker-compose.yml scritp in the current directory {-d} release the console
$ docker-compose up -d

#start executing docker-compose.yml scrip in the current directory {--build} rebuild containers ahead of time
$ docker-compose up --build

#shut down composed containers
$ docker-compose down

#list of docker composed containers 
$ docker-compose ps

#docker compose file with volumes and tests that usese the same container but runs test in it
version: '3'			#compose version
services: 				#container services
	web:				#container name
		build: 
			context: .					#context is as current directory
			dockerfile: Dockerfile.dev	#custom docker file name	
		ports:
			- "3000:3000"
		volumes:		#volume definition
			- /app/node_modules		#mapping of directory to ignore
			- .:/app				#mapping of current docrectory outside to /app inside	
	tests:				#second container name
		build: 
			context: .					#context is as current directory
			dockerfile: Dockerfile.dev	#custom docker file name	
		volumes:		#volume definition
			- /app/node_modules		#mapping of directory to ignore
			- .:/app				#mapping of current docrectory outside to /app inside	
		command: ["npm", "run", "test"]	 #override deault start up command	
		
#docker compose file with multiple services
version: '3'
services:
  postgres:
    image: 'postgres:latest'
  redis:
    image: 'redis:latest'
  nginx:
    build:
      dockerfile: Dockerfile.dev
      context: ./nginx
    ports:
      - '3050:80'
  server:
    build: 
      dockerfile: Dockerfile.dev
      context: ./server
    volumes:
      - /app/node_modules
      - ./server:/app  
    environment:						#this environment varisble are used in application
      - REDSI_HOST=redis				#reference to redis service defined in this compose file
      - REDIS_PORT=6379
      - PGUSER=postgres
      - PGHOST=postgres
      - PGDATABASE=postgres				#postgres to redis service defined in this compose file
      - PGPASSWORD=postgres_password
      - PGPORT=5432
  client: 
    build:
      dockerfile: Dockerfile.dev
      context: ./client
    volumes:
      - /app/node_modules
      - ./client:/app
  worker:
    build:
      dockerfile: Dockerfile.dev
      context: ./worker
    volumes:
      - /app/node_modules
      - ./worker:/app   
	environment:
      - REDSI_HOST=redis
      - REDIS_PORT=6379

	# docker files for this compose
	# nginx
	FROM nginx
	COPY ./default.conf /etc/nginx/conf.d/default.conf
	
	# defailt.conf file for nginx
	upstream client {
    server client:3000;
	}

	upstream api [
		server api:5000;
	]

	server {
		listen 80;

		locatiom / {
			proxt_pass http://client;
		}

		location /api {
			rewrite /api/(.*) /$1 break;
			proxy_pass http://api;
		}
	}
	
	# docker file for client
	FROM node:alpine
	WORKDIR '/app'
	COPY package.json .
	RUN npm install
	COPY . .
	CMD ["npm", "run", "start"]
	
	# docker file for server 
	FROM node:alpine
	WORKDIR '/app'
	COPY package.json .
	RUN npm install
	COPY . .
	CMD ["npm", "run", "dev"]
	
	# docker file for worker
	FROM node:alpine
	WORKDIR '/app'
	COPY package.json .
	RUN npm install
	COPY . .
	CMD ["npm", "run", "dev"]    
	  
#======travisCI

#example of .travis.yml config file
sudo: required							#sudo for docker
services:								#docker service is required
 - docker

before_install: 						#run docker command to build an image beforehand
 - docker build -t artyom366/docker-react -f Dockerfile.dev .	

script:									#run docker command after
 - docker run artyom366/docker-react npm run test -- --coverage
 
 deploy:								#deployment settings (AWS for instance)
  provider: 
  region:
  app:
  env:
  bucket_name:
  bucket_path:
  on:									#deploy on master branch changes
   branch: master
  access_key_id: $SOME_TRAVIS_ENV_VARIABLE
  secret_access_key:
   secure: $SOME_OTHER_TRAVIS_ENV_VARIABLE
   
   
#=======Kubernetes

#apply object config file {pods, services, deployments}
$ kubectl apply -f {file_name.yml}  

#apply multiple config files
$ kubectl apply -f {directory_name}  

#get status of pods/services/deployments/pv/pvc/secret
$ kubectl get pods/services/deployments/pv/pvc/secret

#get status of pods/services/deployments/pv/pvc/secret with additional information
$ kubectl get pods/services/deployments/pv/pvc/secret -o wide

#get detailed information about and object inside cluster
$ kubectl describe pod {pod-name} /service {service-name} /deployment {deployment-name}

#get detailed information about all objects of the same type
$ kubectl describe pod/service/deployment

#delete the object using the same config file that was used for creating the object
$ kubectl delete -f filename.yml

#delete the object by name
$ kubectl delete deployment {object_name: client-deployment}

#manually update image version
$ kubectl set image {object_type: deployment} / {ovbject_name: client-deployment} {container_name: client} = {new_image_or_version: artyom366/multi-client:v2} 

#get logs from pod
$ kubectl logs {pod_name: client-deployment-788d4b9bbb-2mfbg}

#start a pod container shell 
$ kubectl exec -it {-i} {pod_name: client-deployment-788d4b9bbb-2mfbg} sh

#get storage provisioner options
$ kubectl get storageclass

#create secret object in imperative way
$ kubectl create secret gereric {secret_name: pgpassword} --from-literal {key=value: PGPASSWORD=pass}

#=======minikube

$ minikube start
$ minikube ip
$ minikube docker-env -> eval$(minikube docker-env)

#=======Ingress configuration resource
https://kubernetes.github.io/ingress-nginx/deploy/