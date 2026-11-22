MATCH (n)-[r]-()
WITH n, COUNT(r) AS degree
RETURN
    labels(n) AS node_labels,
    coalesce(toString(n.userId), n.title, n.name) AS node,
    degree
ORDER BY degree DESC
LIMIT 20;