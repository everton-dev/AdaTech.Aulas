CREATE TABLE IF NOT EXISTS dim_movie (
    movie_id INTEGER PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    genre VARCHAR(50) NOT NULL,
    release_year SMALLINT NOT NULL CHECK (release_year BETWEEN 1888 AND 2100)
);

CREATE TABLE IF NOT EXISTS dim_user (
    user_id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    age SMALLINT NOT NULL CHECK (age BETWEEN 1 AND 120),
    country VARCHAR(80) NOT NULL
);

CREATE TABLE IF NOT EXISTS fact_rating (
    rating_id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES dim_user(user_id),
    movie_id INTEGER NOT NULL REFERENCES dim_movie(movie_id),
    rating NUMERIC(2,1) NOT NULL CHECK (rating BETWEEN 1 AND 5),
    rated_at DATE NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_fact_rating_movie ON fact_rating(movie_id);
CREATE INDEX IF NOT EXISTS idx_fact_rating_user ON fact_rating(user_id);