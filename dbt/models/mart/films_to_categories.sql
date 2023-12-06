select
	f.title as film, c.name as category
from
	{{ source('source', 'category') }} as c
left join {{ source('source', 'film_category') }} as fc on
	c.category_id = fc.category_id
left join {{ ref('staging_films') }} as f on
	f.film_id = fc.film_id
order by
	f.title