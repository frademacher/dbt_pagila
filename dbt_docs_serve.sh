#!/usr/bin/env bash
cd dbt

noServe=false
for arg in "$@"
do
    [[ "$noServe" == true || "$arg" == "NO_SERVE" ]] && noServe=true || noServe=false
done

dbt docs generate

if [[ "$noServe" == false ]]
then
    dbt docs serve
fi