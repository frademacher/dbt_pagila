FROM ghcr.io/dbt-labs/dbt-postgres:1.7.2 AS run
ARG dbtFilmShareDbUid
ENV DBT_FILM_SHARE_DB_UID=$dbtFilmShareDbUid
WORKDIR /usr/app
COPY dbt dbt
COPY dbt_run.sh .
RUN [ "chmod", "+x", "dbt_run.sh" ]
RUN [ "./dbt_run.sh", "NO_CLEAN" ]

FROM ghcr.io/dbt-labs/dbt-postgres:1.7.2 AS generate_docs
ARG dbtFilmShareDbUid
ENV DBT_FILM_SHARE_DB_UID=$dbtFilmShareDbUid
WORKDIR /usr/app
COPY --from=run /usr/app/dbt .
COPY --from=run /usr/app/dbt/profiles.yml /root/.dbt/profiles.yml
COPY dbt_docs_serve.sh .
RUN [ "chmod", "+x", "dbt_docs_serve.sh" ]
RUN [ "./dbt_docs_serve.sh", "NO_SERVE" ]

FROM nginx:stable-alpine
COPY --from=generate_docs \
    /usr/app/target/index.html \
    /usr/app/target/manifest.json \
    /usr/app/target/catalog.json \
    /usr/app/target/run_results.json \
    /usr/share/nginx/html/
EXPOSE 80