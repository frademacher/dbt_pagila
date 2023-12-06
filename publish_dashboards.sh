#!/usr/bin/env bash
publicationResponse=$(curl --retry 10 \
    --retry-all-errors \
    --retry-max-time 60 \
    -u admin:admin \
    -XPOST 'http://localhost:3000/api/dashboards/uid/ff6f51e3-fa48-4c59-91ce-8fc04dc94282/public-dashboards' \
    -H 'content-type: application/json' \
    --data-raw '{"isEnabled":true}' 2>/dev/null)

if [[ $? == 0 ]]
then
    accessToken=$(echo $publicationResponse | jq -r '.accessToken')
else
    echo "Error: curl returned with exit code $?"
    exit $?
fi

if [[ $accessToken == "null" ]]
then
    echo "Error: Could not retrieve access token for public dashboard access. Original Grafana" \
        "response was $publicationResponse"
else
    export DBT_FILM_SHARE_DB_UID=$accessToken
    echo "Success: Public access token for dashboard is $DBT_FILM_SHARE_DB_UID"
fi