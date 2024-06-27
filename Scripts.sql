# Fetch All the Paintings which are not displayed on any museums.

SELECT 
    *
FROM
    work
WHERE
    museum_id NOT IN (SELECT 
            museum_id
        FROM
            museum);


 # Are there museuems without any paintings?
 
SELECT 
    *
FROM
    museum
WHERE
    museum_id NOT IN (SELECT 
            museum_id
        FROM
            work);
            
            
  #How many paintings have an asking price of more than their regular price?           
 SELECT 
    COUNT(work_id)
FROM
    product_size
WHERE
    sale_price > regular_price;
  
  
  
  #Identify the paintings whose asking price is less than 50% of its regular price
 SELECT 
    *
FROM
    work
        JOIN
    product_size ps ON ps.work_id = work.work_id
WHERE
    work.work_id IN (SELECT 
            work_id
        FROM
            product_size
        WHERE
            sale_price <= (regular_price) / 2)
ORDER BY ps.work_id;

  


  #Which canva size costs the most?
  
 SELECT 
    cs.size_id, cs.label, ps.sale_price
FROM
    canvas_size cs
        JOIN
    product_size ps ON cs.size_id = ps.size_id
WHERE
    ps.sale_price = (SELECT 
            MAX(sale_price)
        FROM
            product_size);
            
            

#Delete duplicate records from work, product_size, subject and image_link tables

-- #Work_Table
-- create temporary table temp_work as
-- select min(work_id) as min_work_id 
-- from work
--     GROUP BY work_id, name, artist_id, style, museum_id
--     HAVING COUNT(*) > 1;
--     
-- delete work
-- from work
-- join temp_work on work.work_id <> temp_work.min_work_id;


-- #product_size
-- create temporary table temp_ps as
-- select min(work_id) as min_work_id
-- from product_size
-- group by work_id, size_id, sale_price, regular_price
-- having count(*) > 1;

-- delete product_size
-- from product_size
-- join temp_ps 
-- on product_size.work_id <> temp_ps.min_work_id;
    
    
#Identify the museums with invalid city information in the given dataset
SELECT 
    *
FROM
    museum m
WHERE
    m.city REGEXP '^[0-9]';
    


#Museum_Hours table has 1 invalid entry. Identify it and remove it.


-- DELETE museum_hours
-- FROM museum_hours
-- LEFT JOIN (
--     SELECT MIN(museum_id) AS min_id
--     FROM museum_hours
--     GROUP BY museum_id, day
-- ) AS keep_rows ON museum_hours.museum_id = keep_rows.min_id
-- WHERE keep_rows.min_id IS NULL;



-- select * from museum_hours
-- where museum_id in (select min(museum_id) from museum_hours
-- 						group by museum_id, day)



#Fetch the top 10 most famous painting subject

select * from(
	select subject, count(1) as No_of_Works,
	rank() over(order by count(1) desc) as Ranking
    from subject 
    join work on
    subject.work_id = work.work_id
    group by subject) x
where Ranking < 11;



# Identify the museums which are open on both Sunday and Monday. Display museum name, city.


SELECT DISTINCT
    (museum_hours.museum_id) AS Museum_id, name, city
FROM
    museum_hours
        JOIN
    museum ON museum_hours.museum_id = museum.museum_id
WHERE
    day = 'Sunday'
        AND EXISTS( SELECT 
            1
        FROM
            museum_hours mh1
        WHERE
            museum_hours.museum_id = mh1.museum_id
                AND mh1.day = 'Monday');


#How many museums are open every single day?

select count(1) 
from (select museum_id, count(1)
		from museum_hours 
        group by museum_id
        having count(1) = 7) x;
        

select museum_id, count(1) as No_of_Days
from museum_hours
group by museum_id
having count(1) = 7; -- More unlikely approach.




#Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)

SELECT 
    work.museum_id,
    museum.name,
    city,
    country,
    COUNT(*) AS No_of_Paintings
FROM
    work
        JOIN
    museum ON work.museum_id = museum.museum_id
WHERE
    work.museum_id NOT LIKE ''
GROUP BY work.museum_id
ORDER BY COUNT(*) DESC
LIMIT 5;


#Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)

select x.artist_id, 
	   x.full_name, 
       x.No_of_Paintings, 
       x.Rankz 
from 
		(select w.artist_id, count(1) as No_of_Paintings, a.full_name,
		rank() over(order by count(1) desc) as Rankz
		from work w
		join artist a
		on w.artist_id = a.artist_id
		group by w.artist_id) x
limit 5;



#Display the 3 least popular canva sizes

select z.size_id, z.label, z.No_of_Paintings, ranking from
		(select cs.size_id, cs.label, count(1) as No_of_Paintings,
		dense_rank() over(order by count(1) asc) as Ranking
		from canvas_size cs
		join product_size ps on cs.size_id = ps.size_id
		join work w on w.work_id = ps.work_id
		group by cs.size_id, cs.label) z
where z.ranking <=3;


#Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
select museum_id, day, name, state, open, close, Museum_Hrs  from
(select m.museum_id, day, name, state, open, close, Concat(cast((close - open) as time), " Hrs") as Museum_Hrs,
rank() over (order by (close - open) desc) as Ranking
from museum_hours
join museum m on m.museum_id = museum_hours.museum_id) z
where Ranking = 1;


#Which museum has the most no of most popular painting style?

with pop_style as                                            #Step 1 - Find the most popular painting style
			(select style, count(1),
			rank() over (order by count(1) desc) ranking
			from work
			group by style),
	pop_mus as                                               #step 2 - Find the most popular museum
			(select m.museum_id, m.name as museum_name, ps.style, count(1) as No_of_Paintings,
            rank() over (order by count(1) desc) as Rnk
            from work w 
            join museum m on w.museum_id = m.museum_id
            join pop_style ps on ps.style = w.style
            where w.museum_id is not null
            and ps.ranking = 1
            group by m.museum_id, m.name, ps.style)
            
select Museum_Name, Style, No_of_Paintings
from pop_mus
where rnk = 1;



# Identify the artists whose paintings are displayed in multiple countries
with cte as(
			select distinct a.full_name as Artist,
            w.name as Painting, m.name as Museum,
            m.country as Country
            from work w
            join artist a on w.artist_id = a.artist_id
            join museum m on m.museum_id = w.museum_id)

select Artist, count(distinct(country)) as No_of_Countries
from cte
group by artist
order by 2 desc
limit 5;


# Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. If there are multiple value, seperate them with comma.
with country as (
				select country, count(1),
                rank() over(order by count(1) desc) as rnk1
                from museum
                group by country),
	 city as (
				select city, count(1),
                rank() over(order by count(1) desc) as rnk2
                from museum
                group by city)
                
select country.country as Country, group_concat(city.city, ',') as City_Cities
from country
join city  on rnk1 = 1 and rnk2 = 1
group by country;


# Identify the artist and the museum where the most expensive and least expensive painting is placed. 
# Display the artist name, sale_price, painting name, museum name, museum city and canvas label


with painting as (
				select work_id, size_id, sale_price,
                rank() over(order by sale_price desc) as Rnk1,
                rank() over(order by sale_price) as Rnk2
                from product_size)
	
select a.full_name As Artist, p.sale_price as Price, w.name as Painting, 
m.name as Museum, m.city as City, cs.label as Label
from painting p 
join work w on w.work_id = p.work_id
join canvas_size cs on cs.size_id = p.size_id
join museum m on m.museum_id = w.museum_id
join artist a on a.artist_id = w.artist_id
where Rnk1 = 1 or Rnk2 = 1;



# Which country has the 5th highest no of paintings?

with cte as (select w.museum_id, country, count(1) as No_of_Paintings, 
			rank() over (order by count(1) desc) as rnk
			from museum 
			join work w on w.museum_id = museum.museum_id
			where w.museum_id not like ''
			group by country)

select Museum_id, Country, No_of_Paintings 
from cte
where rnk = 5;


# Which are the 3 most popular and 3 least popular painting styles?
with cte as (select style, count(1) as Painting_Count, 
			rank() over(order by count(1) desc) as rnk,
            count(1) over() as record_cnt
			from work
			where style not like ''
			group by style)

select Style, Painting_Count,
case when rnk <= 3 then 'Most Popular' else 'Least Popular' end as Remarks,
rnk as Ranking
from cte
where rnk <=3 or rnk > (record_cnt - 3);   #(record_cnt - 3) is 20. So, any rank higher than 20 upto 23 would be the bottom 3 ranked ones.



#Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality?

with cte as(select a.artist_id, a.full_name, count(1) as Paintings, a.nationality, 
			rank() over(order by count(1) desc) as rnk
			from work w 
			join artist a on w.artist_id = a.artist_id
			join museum m on m.museum_id = w.museum_id
            join subject s on s.work_id = w.work_id
			where m.country != 'USA' and s.subject = "Portraits"
			group by a.artist_id)

select full_name as Name, Nationality, Paintings
from cte
where rnk = 1;














	