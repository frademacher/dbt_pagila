#!/usr/bin/env bash
source dbt/docker/docker_image_names.sh
docker build . \
    --no-cache \
    -f dbt/docker/Dockerfile \
    --target run \
    -t $DBT_PAGILA_RUN_IMAGE_NAME \
    --network=host \
    --build-arg dbtFilmShareDbUid="$DBT_FILM_SHARE_DB_UID"

keepImage=false
for arg in "$@"
do
    [[ "$keepImage" == true || "$arg" == "KEEP_IMAGE" ]] && keepImage=true || keepImage=false
done

if [[ "$keepImage" != true ]]
then
    docker rmi $DBT_PAGILA_RUN_IMAGE_NAME
fi