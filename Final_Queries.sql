--DELIVERABLE 2

--Query 1
SELECT ROUND(AVG(PRICE),2) as average_price FROM LISTINGS WHERE BEDS = 8

--Query 2
SELECT ROUND(AVG(l.review_scores_cleanliness), 2) as average_cleanliness_score
FROM listings l, amenities a, includes i
WHERE a.amenity_id = i.amenity_id
AND i.listing_id = l.listing_id
AND a.amenity_name = 'TV'

--Query 3
SELECT DISTINCT l.host_id
FROM listings l, availability a
WHERE l.listing_id = a.listing_id
AND a.date_ >= TO_DATE('2019-03-01', 'YYYY-MM-DD')
AND a.date_ < TO_DATE('2019-10-01', 'YYYY-MM-DD')

--Query 4
SELECT COUNT (*) as number_of_listings
FROM LISTINGS l
WHERE l.host_id IN (
    SELECT DISTINCT h1.host_id
    FROM HOSTS h1, HOSTS h2
    WHERE h1.host_id <> h2.host_id
    AND h1.host_name = h2.host_name)
--optimization CREATE INDEX host_index ON hosts(host_name)

--Query 5
SELECT DISTINCT a.DATE_ as viajes_eco_available_dates
FROM availability a
WHERE a.listing_id IN (
    SELECT l.listing_id 
    FROM listings l, hosts h 
    WHERE h.host_name = 'Viajes Eco'
    AND l.host_id = h.host_id)
--optimization CREATE INDEX host_index ON hosts(host_name)

--Query 6
SELECT l.host_id, h.host_name
FROM listings l, hosts h
WHERE l.host_id = h.host_id
GROUP BY l.host_id, h.host_name
HAVING COUNT (*) = 1

--Query 7
SELECT a.average_price_wifi - b.average_price_no_wifi as price_diff
FROM 
    (
    SELECT ROUND(AVG(l1.price), 2) as average_price_wifi
    FROM listings l1, amenities a, includes i
    WHERE a.amenity_id = i.amenity_id
    AND a.amenity_name = 'Wifi'
    AND i.listing_id = l1.listing_id
    ) a,
    (SELECT ROUND(AVG(l2.price), 2) as average_price_no_wifi
    FROM listings l2
    WHERE l2.listing_id NOT IN (
        SELECT i2.listing_id
        FROM amenities a2, includes i2
        WHERE a2.amenity_id = i2.amenity_id
        AND a2.amenity_name = 'Wifi')
    ) b

--Query 8
SELECT be.average_price_berlin - ma.average_price_madrid as price_diff
FROM 
    (
    SELECT ROUND(AVG(l1.PRICE),2) as average_price_berlin
    FROM listings l1, neighbourhoods n1, located_at la1 
    WHERE l1.listing_id = la1.listing_id
    AND la1.neighbourhood_id = n1.neighbourhood_id
    AND n1.city = 'Berlin'
    AND l1.BEDS = 8
    ) be,
    (
    SELECT ROUND(AVG(l2.PRICE),2) as average_price_madrid
    FROM listings l2, neighbourhoods n2, located_at la2 
    WHERE l2.listing_id = la2.listing_id
    AND la2.neighbourhood_id = n2.neighbourhood_id
    AND n2.city = 'Madrid'
    AND l2.BEDS = 8
    ) ma

--Query 9
SELECT m.host_id, m.host_name, m.Rank 
FROM 
    (
    SELECT l.host_id, h.host_name, COUNT(*), RANK() OVER (ORDER BY COUNT(*) DESC) Rank
    FROM listings l, hosts h, located_at la, neighbourhoods n
    WHERE l.host_id = h.host_id
    AND l.listing_id = la.listing_id
    AND la.neighbourhood_id = n.neighbourhood_id
    AND n.country_code = 'ES'
    GROUP BY l.host_id, h.host_name
    ) m
WHERE Rank <= 10

--Query 10
SELECT m.listing_id, m.listing_name, m.Rank 
FROM 
    (
    SELECT l.listing_id, l.listing_name, RANK() OVER (ORDER BY l.review_scores_rating DESC) Rank
    FROM listings l, located_at la, neighbourhoods n
    WHERE l.listing_id = la.listing_id
    AND la.neighbourhood_id = n.neighbourhood_id
    AND n.city = 'Barcelona'
    AND l.listing_type = 'Apartment'
    AND l.review_scores_rating is not null
    ) m
WHERE m.Rank <= 10




--DELIVERABLE 3

--Query 1
SELECT n.city, COUNT(DISTINCT l.host_id) as NUMBER_OF_HOSTS
FROM listings l, located_at la, neighbourhoods n
WHERE l.listing_id = la.listing_id
AND la.neighbourhood_id = n.neighbourhood_id
AND l.square_feet is not null
AND l.square_feet <> 0
GROUP BY n.city
ORDER BY n.city

--Query 2
SELECT * FROM 
    (
    SELECT l1.neighbourhood_name,  RANK() OVER (ORDER BY m2.review_scores_rating DESC, l1.number_of_listings DESC) Rank
    FROM 
        (
        SELECT n.neighbourhood_name, n.neighbourhood_id ,COUNT(*) as number_of_listings 
        FROM neighbourhoods n, located_at la, listings l
        WHERE n.neighbourhood_id = la.neighbourhood_id
        AND la.listing_id = l.listing_id
        AND n.city = 'Madrid'
        GROUP BY n.neighbourhood_name, n.neighbourhood_id
        ) l1,
        (
        SELECT l2.review_scores_rating, la2.neighbourhood_id
        FROM located_at la2, listings l2
        WHERE la2.listing_id = l2.listing_id
        AND l2.listing_id IN 
            (
            SELECT x3.listing_id FROM 
                (
                SELECT x1.*, x2.median_row, rownum r
                FROM 
                    (
                    SELECT l3.listing_id
                    FROM listings l3, located_at la3
                    WHERE l3.listing_id = la3.listing_id
                    AND la3.neighbourhood_id = la2.neighbourhood_id
                    AND l3.review_scores_rating is not null
                    ORDER BY l3.review_scores_rating desc
                    ) x1,
                    (
                    SELECT ROUND(COUNT(*)/2) as median_row 
                    FROM
                        (
                        SELECT l4.listing_id
                        FROM listings l4, located_at la4
                        WHERE l4.listing_id = la4.listing_id
                        AND la4.neighbourhood_id = la2.neighbourhood_id
                        AND l4.review_scores_rating is not null
                        ORDER BY l4.review_scores_rating desc
                        )
                    ) x2
                ) x3
            WHERE x3.r = x3.median_row
            )
        ) m2
    WHERE l1.neighbourhood_id = m2.neighbourhood_id
    )
WHERE Rank <= 5

--Query 3
SELECT host_id, host_name 
FROM
    (
    SELECT m.host_id, m.host_name, RANK() OVER (ORDER BY number_of_listings DESC) Rank
    FROM
        (
        SELECT h.host_id, h.host_name, COUNT(*) as number_of_listings
        FROM listings l, hosts h
        WHERE l.host_id = h.host_id
        GROUP BY h.host_id, h.host_name
        ) m
    ) 
WHERE Rank = 1

--Query 4
SELECT m2.listing_id, m2.avg_price FROM 
    (
    SELECT m1.*, RANK() OVER (ORDER BY avg_price) Rank FROM
        (
        SELECT l.listing_id, ROUND(AVG(a.price),2) as avg_price
        FROM listings l, located_at la, neighbourhoods n, availability a, verified_through vt, verification_channels vc
        WHERE l.listing_id = la.listing_id
        AND la.neighbourhood_id = n.neighbourhood_id
        AND a.listing_id = l.listing_id
        AND vt.host_id = l.host_id
        AND vc.verification_channel_id = vt.verification_channel_id
        AND n.city = 'Berlin'
        AND l.listing_type = 'Apartment'
        AND a.date_ >= to_date('01-MAR-19','DD-MON-YY')
        AND a.date_ <= to_date('30-APR-19','DD-MON-YY')
        AND l.beds >= 2
        AND l.review_scores_location >= 8
        AND l.cancellation_policy = 'flexible'
        AND vc.verification_channel_name = 'government_id'
        GROUP BY l.listing_id
        ) m1
    ) m2
WHERE m2.Rank <= 5

--Query 5
SELECT * FROM 
    (
    SELECT m.accommodates, m.listing_id,
    RANK() OVER (PARTITION BY m.accommodates ORDER BY m.review_scores_rating DESC) Rank
    FROM 
        ( 
        SELECT l.accommodates, l.listing_id, l.review_scores_rating
        FROM listings l, includes i, amenities a
        WHERE i.listing_id = l.listing_id
        AND i.amenity_id = a.amenity_id
        AND a.amenity_name IN ('Wifi', 'Internet', 'TV', 'Free street parking')
        AND l.review_scores_rating is not null
        GROUP BY l.listing_id, l.accommodates, l.review_scores_rating
        HAVING COUNT(*) > 1
        ) m
    )
WHERE RANK <= 5

--Query 6
SELECT * FROM 
    (
    SELECT m1.host_id, m1.listing_id, m1.popularity, RANK() OVER (PARTITION BY m1.host_id ORDER BY popularity DESC) Rank
        FROM
        (
        SELECT l.host_id, l.listing_id, COUNT(*) as popularity
        FROM listings l, reviewed r
        WHERE l.listing_id = r.listing_id
        GROUP BY l.host_id, l.listing_id
        ) m1
    ) m2
WHERE m2.rank <= 3
ORDER BY m2.host_id
--optimization CREATE INDEX listing_review_index ON reviewed(listing_id)

--Query 7
SELECT * FROM
    (
    SELECT m.neighbourhood_name, m.amenity_name, m.popularity, RANK() OVER (PARTITION BY m.neighbourhood_name ORDER BY m.popularity DESC) Rank
    FROM
        (
        SELECT n.neighbourhood_name, a.amenity_name, COUNT(*) as popularity
        FROM listings l, located_at la, neighbourhoods n, includes i, amenities a
        WHERE l.listing_id = la.listing_id
        AND la.neighbourhood_id = n.neighbourhood_id
        AND l.listing_id = i.listing_id
        AND i.amenity_id = a.amenity_id
        AND n.city = 'Berlin'
        AND l.room_type = 'Private room'
        GROUP BY n.neighbourhood_name, a.amenity_name
        ) m
    )
WHERE Rank <= 3
--optimization CREATE INDEX room_type_index ON listings(room_type)

--Query 8
SELECT maxh.avg_comm_score - minh.avg_comm_score as difference
FROM
    (
    SELECT * FROM
        (
        SELECT m1.host_id, m1.avg_comm_score, m2.diversity 
        FROM 
            (
            SELECT l.host_id, avg(l.review_scores_communication) as avg_comm_score
            FROM listings l
            WHERE l.review_scores_communication is not null
            GROUP BY l.host_id
            ) m1,
            (
            SELECT h.host_id, COUNT(*) as diversity
            FROM hosts h, verified_through vt
            WHERE vt.host_id = h.host_id
            GROUP BY h.host_id
            ) m2
        WHERE m1.host_id = m2.host_id
        ORDER BY m2.diversity desc
        )
    WHERE ROWNUM = 1
    ) maxh,
    (
    SELECT * FROM
        (
        SELECT m1.host_id, m1.avg_comm_score, m2.diversity 
        FROM 
            (
            SELECT l.host_id, avg(l.review_scores_communication) as avg_comm_score
            FROM listings l
            WHERE l.review_scores_communication is not null
            GROUP BY l.host_id
            ) m1,
            (
            SELECT h.host_id, COUNT(*) as diversity
            FROM hosts h
            LEFT OUTER JOIN verified_through vt ON vt.host_id = h.host_id
            GROUP BY h.host_id
            ) m2
        WHERE m1.host_id = m2.host_id
        ORDER BY m2.diversity asc
        )
    WHERE ROWNUM = 1
    ) minh

--Query 9
SELECT city FROM 
    (
    SELECT m2.*, RANK() OVER (ORDER BY number_of_reviews DESC) Rank
    FROM 
        (
        SELECT m1.city, COUNT(*) as number_of_reviews
        FROM 
            (
            SELECT l.listing_id, n.city
            FROM listings l, located_at la, neighbourhoods n
            WHERE l.listing_id = la.listing_id
            AND la.neighbourhood_id = n.neighbourhood_id
            AND l.room_type IN 
                (
                SELECT l2.room_type
                FROM listings l2
                GROUP BY l2.room_type
                HAVING AVG(l2.accommodates) > 3
                )
            ) m1, 
            reviewed re
        WHERE re.listing_id = m1.listing_id
        GROUP BY m1.city
        ) m2
    )
WHERE RANK = 1

--Query 10
SELECT n.neighbourhood_name
FROM neighbourhoods n
WHERE n.city = 'Madrid'
AND EXISTS (
    SELECT * FROM
        (
        SELECT COUNT(*) as occupied 
        FROM 
            (
            SELECT l1.listing_id, COUNT(*) as days_free_in_19
            FROM listings l1, located_at la1, hosts h1, availability a1
            WHERE l1.listing_id = la1.listing_id
            AND la1.neighbourhood_id = n.neighbourhood_id
            AND h1.host_id = l1.host_id
            AND l1.listing_id = a1.listing_id
            AND h1.host_since < to_date('01-JUN-17','DD-MON-YY')
            AND a1.date_ > to_date('31-DEC-18','DD-MON-YY')
            GROUP BY l1.listing_id
            ) m1
        WHERE m1.days_free_in_19 < (SELECT COUNT (DISTINCT DATE_) as days_in_19 FROM DAYS WHERE DATE_ > to_date('31-DEC-18','DD-MON-YY'))
        ) x1,
        (
        SELECT COUNT(*) as total
        FROM listings l2, located_at la2
        WHERE l2.listing_id = la2.listing_id
        AND la2.neighbourhood_id = n.neighbourhood_id
        ) x2
    WHERE x1.occupied/x2.total >= 0.5
    )

--Query 11
SELECT l1.country
FROM 
    (
    SELECT n.country, COUNT(DISTINCT a.listing_id) as available_listings
    FROM availability a, located_at la, neighbourhoods n
    WHERE a.listing_id = la.listing_id
    AND la.neighbourhood_id = n.neighbourhood_id
    AND a.date_ < to_date('01-JAN-19','DD-MON-YY')
    GROUP BY n.country
    ) l1, 
    (
    SELECT n1.country, COUNT(DISTINCT la1.listing_id) as total_listings
    FROM located_at la1, neighbourhoods n1
    WHERE la1.neighbourhood_id = n1.neighbourhood_id
    GROUP BY n1.country
    ) l2
WHERE l1.country = l2.country
AND l1.available_listings / l2.total_listings >= 0.2
--optimization CREATE INDEX date_index ON availability(date_)

--Query 12
SELECT n.neighbourhood_name
FROM neighbourhoods n
WHERE n.city = 'Barcelona'
AND EXISTS (
    SELECT * FROM 
        (
        SELECT m1.strict_w_grace/m2.no_of_listings as ratio
        FROM
            (
            SELECT COUNT(*) as strict_w_grace
            FROM listings l2, located_at la2
            WHERE l2.listing_id = la2.listing_id
            AND la2.neighbourhood_id = n.neighbourhood_id
            AND l2.cancellation_policy = 'strict_14_with_grace_period'
            ) m1,
            (
            SELECT COUNT(*) as no_of_listings
            FROM listings l3, located_at la3
            WHERE l3.listing_id = la3.listing_id
            AND la3.neighbourhood_id = n.neighbourhood_id
            ) m2
        ) m3
    WHERE m3.ratio > 0.05)