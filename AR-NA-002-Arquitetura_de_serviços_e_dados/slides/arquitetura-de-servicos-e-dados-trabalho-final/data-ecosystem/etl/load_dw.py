import csv
import os
from pathlib import Path

import psycopg


def read_csv(path: Path, fields: tuple[str, ...]) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as source:
        reader = csv.DictReader(source)
        if tuple(reader.fieldnames or ()) != fields:
            raise ValueError(f"Cabecalho invalido em {path.name}: {reader.fieldnames}")
        return list(reader)


def load() -> None:
    datalake = Path(os.getenv("DATALAKE_PATH", "/datalake"))
    movies = read_csv(datalake / "movies.csv", ("movie_id", "title", "genre", "release_year"))
    users = read_csv(datalake / "users.csv", ("user_id", "name", "age", "country"))
    ratings = read_csv(datalake / "ratings.csv", ("rating_id", "user_id", "movie_id", "rating", "rated_at"))

    connection_info = {
        "host": os.getenv("DW_HOST", "db-dw"),
        "port": int(os.getenv("DW_PORT", "5432")),
        "user": os.getenv("DW_USER", "dw_user"),
        "password": os.getenv("DW_PASSWORD", "dw_pass"),
        "dbname": os.getenv("DW_NAME", "movieflix_dw"),
    }

    with psycopg.connect(**connection_info) as connection:
        with connection.cursor() as cursor:
            cursor.execute("TRUNCATE fact_rating, dim_user, dim_movie")
            cursor.executemany(
                "INSERT INTO dim_movie (movie_id, title, genre, release_year) VALUES (%s, %s, %s, %s)",
                [(row["movie_id"], row["title"], row["genre"], row["release_year"]) for row in movies],
            )
            cursor.executemany(
                "INSERT INTO dim_user (user_id, name, age, country) VALUES (%s, %s, %s, %s)",
                [(row["user_id"], row["name"], row["age"], row["country"]) for row in users],
            )
            cursor.executemany(
                "INSERT INTO fact_rating (rating_id, user_id, movie_id, rating, rated_at) VALUES (%s, %s, %s, %s, %s)",
                [
                    (row["rating_id"], row["user_id"], row["movie_id"], row["rating"], row["rated_at"])
                    for row in ratings
                ],
            )

    print(f"Carga concluida: {len(movies)} filmes, {len(users)} usuarios, {len(ratings)} avaliacoes.")


if __name__ == "__main__":
    load()