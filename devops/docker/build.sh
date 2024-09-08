
# ./build.sh image tag1 tag2
IMAGE=$1

docker save $IMAGE | docker run  -v /tmp -i myyk/docker-squash -t $IMAGE -t $2 -t $3 -verbose | docker load