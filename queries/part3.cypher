# Запит 1. Знайти всі фільми жанру «Thriller» із середнім рейтингом вище 4.0:

MATCH (m:Movie)-[:HAS_GENRE]->(g:Genre {name: 'Thriller'})
MATCH (m)<-[r:RATED]-(:User)
WITH m, AVG(r.rating) AS avg_rating, COUNT(r) AS ratings_count
WHERE avg_rating > 4.0
RETURN
    m.title AS movie,
    ROUND(avg_rating, 2) AS average_rating,
    ratings_count
ORDER BY average_rating DESC;

# Запит 2. Знайти користувачів, які поставили оцінку 5 більш ніж 50 фільмам:

MATCH (u:User)-[r:RATED]->(m:Movie)
WHERE r.rating = 5
WITH u, COUNT(DISTINCT m) AS movies_count
WHERE movies_count > 50
RETURN
    u.userId AS user_id,
    movies_count
ORDER BY movies_count DESC;

# Запит 3. Знайти фільми, які обидва користувачі (наприклад, userId=1 і userId=2) оцінили високо (рейтинг ≥ 4):

MATCH (u1:User {userId: 1})-[r1:RATED]->(m:Movie)
      <-[r2:RATED]-(u2:User {userId: 2})
WHERE r1.rating >= 4 AND r2.rating >= 4
RETURN
    m.title AS movie,
    r1.rating AS user1_rating,
    r2.rating AS user2_rating
ORDER BY m.title;

# Запит 4. Знайти жанри, чиї фільми стабільно отримують високі оцінки — середній рейтинг і кількість оцінок:

MATCH (g:Genre)<-[:HAS_GENRE]-(m:Movie)<-[r:RATED]-(:User)
WITH
    g,
    AVG(r.rating) AS avg_rating,
    COUNT(r) AS ratings_count,
    COUNT(DISTINCT m) AS movies_count
WHERE avg_rating >= 3.5 AND ratings_count >= 1000
RETURN
    g.name AS genre,
    ROUND(avg_rating, 2) AS average_rating,
    ratings_count,
    movies_count
ORDER BY average_rating DESC, ratings_count DESC;

# Запит 5. Рекомендація «користувачі зі схожими смаками також дивилися»: для заданого користувача знайти фільми, які він ще не дивився, але високо оцінили користувачі з подібними смаками:

MATCH (target:User {userId: 1})-[r1:RATED]->(common:Movie)
      <-[r2:RATED]-(similar:User)
WHERE r1.rating >= 4
  AND r2.rating >= 4
  AND target <> similar

WITH target, similar, COUNT(DISTINCT common) AS common_movies
WHERE common_movies >= 3

MATCH (similar)-[r3:RATED]->(recommended:Movie)
WHERE r3.rating >= 4
  AND NOT EXISTS {
      MATCH (target)-[:RATED]->(recommended)
  }

WITH
    recommended,
    COUNT(DISTINCT similar) AS similar_users,
    SUM(common_movies) AS recommendation_score,
    AVG(r3.rating) AS avg_rating

RETURN
    recommended.title AS movie,
    similar_users,
    recommendation_score,
    ROUND(avg_rating, 2) AS average_rating
ORDER BY recommendation_score DESC, similar_users DESC
LIMIT 20;

# Запит 6. Знайти найкоротший ланцюжок зв’язку між двома користувачами через спільні фільми:

MATCH (u1:User {userId: 1})
MATCH (u2:User {userId: 2})

MATCH p = shortestPath(
    (u1)-[:RATED*..6]-(u2)
)

RETURN
    p AS shortest_path,
    length(p) AS path_length;