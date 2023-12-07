# dbt_pagila: `dbt` Workflow Demo with the Pagila Example Database and Grafana Dashboard Support

This repository exemplifies the usage of [`dbt`](https://www.getdbt.com). More precisely, we
leverage `dbt` to specify ELT workflows, execute them on a
[Postgres DBMS](https://www.postgresql.org/) that is initialized with the
[Pagila example database](https://github.com/devrimgunduz/pagila), and provide
[Grafana](https://grafana.com) dashboards for the visualization of transformed data.

**Note that the code in this repository does not respect any security policies and is intended for
demonstration purposes only. Among others, credentials are hardcoded into plain text files. You do
not want to run this in a production environment.**

## Quick Start

Required dependencies:
  - [curl](https://curl.se)
  - [Docker (including Compose)](https://www.docker.com/)
  - [jq](https://jqlang.github.io/jq)

1. Clone this repository.
2. Open a terminal and `cd` into the cloned repository folder.
3. Run `docker compose up -d && source publish_dashboards.sh` (may take a while).
4. Run `./docker_dbt_run.sh && ./docker_dbt_docs_serve.sh`.
5. Navigate to [http://localhost:8080](http://localhost:8080).

### What Happened?

Step 3 uses Docker to fire up the following containers:
  - Postgres DBMS with the Pagila database in the `source` schema
  - [pgAdmin](https://www.pgadmin.org) at [http://localhost:5050](http://localhost:5050) with
    credentials `admin@admin.com:root`
  - Grafana at [http://localhost:3000](http://localhost:3000) with credentials `admin:admin`

Furthermore, Step 3 `source`s [publish_dashboards.sh](publish_dashboards.sh) to (i) set the
visibility of pre-configured Grafana dashboards (see [grafana/dashboards](grafana/dashboards))
to public; and, upon success, (ii) export the access tokens for these dashboards into the local
execution environment. For example, the terminal command `echo $DBT_FILM_SHARE_DB_UID` prints out
the access token for the Grafana dashboard that displays the share of films per category from the
Pagila database (see below Behind the Curtain: Technical Details of a `dbt` Workflow).

Step 4 executes the [docker_dbt_run.sh](docker_dbt_run.sh) script which employs Docker to run the
ELT workflows specified in the [dbt](dbt) folder (the concrete `dbt` commands can be found in
[dbt_run.sh](dbt_run.sh)). Note that [docker_dbt_run.sh](docker_dbt_run.sh) assumes
[publish_dashboards.sh](publish_dashboards.sh) (see Step 3) to have been run before because the
specified `dbt` exposures require the access tokens of the publicized Grafana dashboards.

Additionally, Step 4 executes the [docker_dbt_docs_serve.sh](docker_dbt_docs_serve.sh) script. It
generates and serves the HTML documentation for the specified `dbt` workflows.

Step 5 opens the HTML documentation for the specified `dbt` workflows at
[http://localhost:8080](http://localhost:8080). As described above, the Docker container started by
[docker_dbt_docs_serve.sh](docker_dbt_docs_serve.sh) serves the documentation.

## Behind the Curtain: Technical Details of a `dbt` Workflow

This repository specifies a simple `dbt` workflow which
  1. extracts Pagila's `film` table and loads it into a staging schema;
  2. transforms the staged `film` table, using Pagila's `category` and `films_to_categories` tables,
     into the `films_to_categories` table as part of an analytical schema, thereby permitting, e.g.,
     the calculation of the share of films per category; and
  3. configures an exposure for a public Grafana dashboard that displays the share of films per
     category in a pie chart.

### Details on Step 1

The extraction and loading of the `film` table is specified in the
[dbt/models/staging/staging_films.sql](dbt/models/staging/staging_films.sql) `dbt` model. For the
most parts, the model specifies a copy of the table. It only performs a slight modification on the
`title` column whose values are converted into proper case using Postgres's
[`initcap()`](https://www.postgresql.org/docs/13/functions-string.html) function. To this end, the
model operates on Pagila's original `film` table, which is located in the database's `source`
schema, by referencing it with `dbt`'s
[`source()`](https://docs.getdbt.com/reference/dbt-jinja-functions/source) function.

This referencing is possible because we configure the table as a `dbt` source in
[dbt/models/sources.yml](dbt/models/sources.yml). The file also activates some tests on the table
to assure its integrity for the upcoming transformation (see Details on Step 2).

`dbt` persists the result of `film`'s extraction and loading in the `staging_films` table (named
after the filename of the model's SQL specification in
[dbt/models/staging/staging_films.sql](dbt/models/staging/staging_films.sql)) within the
`source_staging` schema. This schema is configured in [dbt/dbt_project.yml](dbt/dbt_project.yml) for
all models in [dbt/models/staging](dbt/models/staging) to clearly separate operational source data
from transformational and analytical data produced by ELT workflows. Note
that the configured name of the schema (`staging`) diverges from the physically created schema
(`source_staging`) because `dbt` precedes configured names of target schemas with the names of
source schemas.

### Details on Step 2

The transformation of the staged `films` table (conceptually the `staging_films` model, physically
the `source_staging.staging_films` table) in combination with the `category` and `film_category`
tables from Pagila's `source` schema is specified in the
[dbt/models/mart/films_to_categories.sql](dbt/models/mart/films_to_categories.sql) `dbt` model. The
execution of the model produces the `films_to_categories` table in the `mart` schema (see
[dbt/dbt_project.yml](dbt/dbt_project.yml)).

Essentially, the `films_to_categories` model is a join table of the `staging_films` staged table and
`category` source table. That is, `films_to_categories` identifies for each film title in proper
case (see Details on Step 1) the corresponding film category.

As per [dbt/dbt_project.yml](dbt/dbt_project.yml), `dbt` grants a Postgres user called `mart_read`
select privileges on `films_to_categories`. This user is created upon the start of the Postgres
container (see Step 3 in Quick Start) via the
[pagila/create-mart-read.sql](pagila/create-mart-read.sql) script. However, because `dbt` drops ELT
target schemas upon execution, we grant `mart_read` usage privileges on the `source_mart` schema by
means of `dbt`'s `on-run-start` hook in [dbt/dbt_project.yml](dbt/dbt_project.yml). Grafana relies
on this user to perform queries against the `source_mart` analytical schema for dashboard
provisioning (see also
[grafana/provisioning/datasources/datasources.yml](grafana/provisioning/datasources/datasources.yml)).

### Details on Step 3

The `films_to_categories` model is part of a `dbt` exposure called `film_share_per_category` and
configured in [dbt/models/mart/exposures.yml](dbt/models/mart/exposures.yml). The exposure points to
a pre-configured Grafana dashboard (see
[grafana/dashboards/film_count_per_category.json](grafana/dashboards/film_count_per_category.json))
that displays the share of films per category in the Pagila database based on the analytical table
`source_mart.films_to_categories`, which `dbt` produces from the `films_to_categories` model.

The `film_share_per_category` dashboard gets publicized during Step 3 of the Quick Start. Note that
`dbt` expects the `DBT_FILM_SHARE_DB_UID` environment variable to hold the access token of the
publicized dashboard (see What Happened?) because the `dbt` exposure's `url` is templated with the
statement `env_var('DBT_FILM_SHARE_DB_UID')`.

By executing [docker_dbt_docs_serve.sh](docker_dbt_docs_serve.sh) (see Step 4 in Quick Start), `dbt`
generates the HTML documentation of the specified workflows, which also includes the
`film_share_per_category` exposure, and serves it at [http://localhost:8080](http://localhost:8080)
(see Step 5 in Quick Start). The `dbt`-generated lineage graph for the `films_to_categories`
analytical model and the exposure looks as follows:

![`films_to_categories` Lineage Graph](lineage-graph.png)