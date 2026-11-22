# 2.1 Створення індексів

CREATE INDEX user_id_index IF NOT EXISTS
FOR (u:User) ON (u.userId);

CREATE INDEX movie_id_index IF NOT EXISTS
FOR (m:Movie) ON (m.movieId);

CREATE INDEX genre_name_index IF NOT EXISTS
FOR (g:Genre) ON (g.name);

# 2.2. Завантаження користувачів

LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
MERGE (u:User {userId: toInteger(row.userId)})
SET
    u.gender = row.gender,
    u.age = toInteger(row.age),
    u.occupation = toInteger(row.occupation);

# 2.3. Завантаження фільмів

LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
WITH row,
     CASE
         WHEN right(row.title, 6) =~ '\\([0-9]{4}\\)'
         THEN toInteger(substring(row.title, size(row.title) - 5, 4))
         ELSE null
     END AS movieYear

MERGE (m:Movie {movieId: toInteger(row.movieId)})
SET
    m.title = row.title,
    m.year = movieYear;

# 2.4. Завантаження жанрів та зв'язків HAS_GENRE

LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
MATCH (m:Movie {movieId: toInteger(row.movieId)})
UNWIND split(row.genres, '|') AS genreName
MERGE (g:Genre {name: genreName})
MERGE (m)-[:HAS_GENRE]->(g);

# 2.5. Завантаження оцінок через apoc.periodic.iterate

CALL apoc.periodic.iterate(
    "
    LOAD CSV WITH HEADERS FROM 'file:///ratings.csv' AS row
    RETURN row
    ",
    "
    MATCH (u:User {userId: toInteger(row.userId)})
    MATCH (m:Movie {movieId: toInteger(row.movieId)})

    MERGE (u)-[r:RATED]->(m)

    SET
        r.rating = toInteger(row.rating),
        r.timestamp = toInteger(row.timestamp)
    ",
    {
        batchSize: 10000,
        parallel: false
    }
)
YIELD batches, total, failedOperations, errorMessages

RETURN batches, total, failedOperations, errorMessages;

# 2.6. Перевірка результатів

MATCH (u:User)
RETURN count(u) AS users;

MATCH (m:Movie)
RETURN count(m) AS movies;

MATCH (g:Genre)
RETURN count(g) AS genres;

MATCH ()-[r:RATED]->()
RETURN count(r) AS ratings;

MATCH ()-[r:HAS_GENRE]->()
RETURN count(r) AS genre_relationships;

# 2.7. Візуалізація графа

MATCH (u:User)-[r:RATED]->(m:Movie)-[hg:HAS_GENRE]->(g:Genre)
RETURN u, r, m, hg, g
LIMIT 25;