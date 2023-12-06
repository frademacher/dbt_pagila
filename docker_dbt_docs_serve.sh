#!/usr/bin/env bash
source dbt/docker/docker_image_names.sh
docker build . \
    --no-cache \
    -f dbt/docker/Dockerfile \
    -t $DBT_PAGILA_DOCS_IMAGE_NAME \
    --network=host \
    --build-arg dbtFilmShareDbUid="$DBT_FILM_SHARE_DB_UID"

docker run -p 8080:80 $DBT_PAGILA_DOCS_IMAGE_NAME