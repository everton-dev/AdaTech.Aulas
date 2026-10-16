-- 1. Os cinco filmes mais populares por quantidade de avaliacoes.
SELECT movie.title, movie.genre, COUNT(*) AS rating_count
FROM fact_rating AS rating
JOIN dim_movie AS movie ON movie.movie_id = rating.movie_id
GROUP BY movie.movie_id, movie.title, movie.genre
ORDER BY rating_count DESC, movie.title
LIMIT 5;

-- 2. O genero com a melhor avaliacao media.
SELECT movie.genre, ROUND(AVG(rating.rating), 2) AS average_rating
FROM fact_rating AS rating
JOIN dim_movie AS movie ON movie.movie_id = rating.movie_id
GROUP BY movie.genre
ORDER BY average_rating DESC, movie.genre
LIMIT 1;

-- 3. O pais que mais assiste/avalia filmes.
SELECT app_user.country, COUNT(*) AS rating_count
FROM fact_rating AS rating
JOIN dim_user AS app_user ON app_user.user_id = rating.user_id
GROUP BY app_user.country
ORDER BY rating_count DESC, app_user.country
LIMIT 1;