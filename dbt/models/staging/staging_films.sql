select
	film_id,
	initcap(title) as title,
	description,
	release_year,
	language_id,
	original_language_id,
	rental_duration,
	rental_rate,
	length,
	replacement_cost,
	rating,
	last_update,
	special_features,
	fulltext
from {{ source('source', 'film') }}