SELECT * FROM c

SELECT * FROM c WHERE c.id = "c73d2994-3c42-4a77-a30c-247fb0004259"

SELECT * FROM c WHERE c.address.city = "Porto"

SELECT * FROM c WHERE c.address.city = "Lisboa"

SELECT * FROM c
WHERE ARRAY_LENGTH(
    ARRAY(
        SELECT VALUE o
        FROM o IN c.orders
        WHERE ARRAY_LENGTH(o.items) > 2
    )
) > 0


SELECT * FROM c ORDER BY c.name
SELECT UPPER(c.name) FROM c ORDER BY c.name
SELECT c.type, COUNT(1) AS Qty FROM c GROUP BY c.type ORDER BY c.type