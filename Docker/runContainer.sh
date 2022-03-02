#!/bin/bash

#Will run the latest version of the container image
#Binds port 8000 in the container to port 8000 on localhost
#for viewing telemetry dashboard in web browser
#Go to https://127.0.0.1:8000 once container is running
docker run -ti --rm -p 8000:8000 cyclops_demo_local:latest