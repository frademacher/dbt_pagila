#!/usr/bin/env bash
cd dbt

clean=true
for arg in "$@"
do
    [[ "$clean" == true && "$arg" == "NO_CLEAN" ]] && clean=false || clean=true
done

if [[ "$clean" == true ]]
then
    dbt clean
fi

dbt deps && dbt run && dbt test