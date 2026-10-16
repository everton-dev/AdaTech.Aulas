DROP VIEW IF EXISTS vw_top_10_movies_by_genre;
DROP VIEW IF EXISTS vw_average_rating_by_age_group;
DROP VIEW IF EXISTS vw_ratings_by_country;

CREATE VIEW vw_top_10_movies_by_genre AS
WITH ranked_movies AS (
    SELECT
        movie.genre,
        movie.movie_id,
        movie.title,
        ROUND(AVG(rating.rating), 2) AS average_rating,
        COUNT(*) AS rating_count,
        ROW_NUMBER() OVER (
            PARTITION BY movie.genre
            ORDER BY AVG(rating.rating) DESC, COUNT(*) DESC, movie.title
        ) AS genre_rank
    FROM dim_movie AS movie
    JOIN fact_rating AS rating ON rating.movie_id = movie.movie_id
    GROUP BY movie.genre, movie.movie_id, movie.title
)
SELECT genre, movie_id, title, average_rating, rating_count, genre_rank
FROM ranked_movies
WHERE genre_rank <= 10;

CREATE VIEW vw_average_rating_by_age_group AS
SELECT
    CASE
        WHEN app_user.age < 18 THEN 'Abaixo de 18'
        WHEN app_user.age BETWEEN 18 AND 24 THEN '18-24'
        WHEN app_user.age BETWEEN 25 AND 34 THEN '25-34'
        WHEN app_user.age BETWEEN 35 AND 44 THEN '35-44'
        WHEN app_user.age BETWEEN 45 AND 54 THEN '45-54'
        ELSE '55+'
    END AS age_group,
    ROUND(AVG(rating.rating), 2) AS average_rating,
    COUNT(*) AS rating_count
FROM dim_user AS app_user
JOIN fact_rating AS rating ON rating.user_id = app_user.user_id
GROUP BY age_group;

CREATE VIEW vw_ratings_by_country AS
SELECT
    app_user.country,
    COUNT(*) AS rating_count,
    ROUND(AVG(rating.rating), 2) AS average_rating
FROM dim_user AS app_user
JOIN fact_rating AS rating ON rating.user_id = app_user.user_id
GROUP BY app_user.country;