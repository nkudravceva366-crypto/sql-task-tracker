-- ==================================================
-- Week 03 — SQL Tasks (1-12)
-- Educational airbase database
-- Topics: subqueries, aggregates, HAVING, joins, delays, revenue
-- ==================================================

-- Task 1
-- Aircraft with range greater than average:
-- airplane code, model in Russian, flight range.

select
airplane_code,
model ->> 'ru' as model_ru,
range
from airplanes_data
where range > (
select avg(range)
from airplanes_data
)
order by range desc, airplane_code;

-- Task 2
-- Find bookings for passenger Franklin Meyer:
-- book_ref and total_amount.

select distinct
b.book_ref,
b.total_amount
from bookings as b
join tickets as t
on t.book_ref = b.book_ref
where t.passenger_name = 'Franklin Meyer'
order by b.book_ref;

-- Task 3
-- Find only one value: the second largest distinct maximum flight price
-- from the segments table.

select price as second_max_price
from (
select distinct price
from segments
order by price desc
offset 1
limit 1
) as second_price;

-- Task 4
-- Use a subquery directly in the SELECT list.
-- Output booking number, total amount and number of tickets inside each booking.
-- Sort by number of tickets descending, then by book_ref.
-- Limit result to 10 rows.

select
b.book_ref,
b.total_amount,
(
select count(*)
from tickets as t
where t.book_ref = b.book_ref
) as tickets_count
from bookings as b
order by tickets_count desc, b.book_ref
limit 10;

-- Task 5
-- Output flight_id, scheduled departure time and total revenue,
-- but only for flights where revenue exceeded 15,000,000.

select
f.flight_id,
f.scheduled_departure,
sum(s.price) as total_revenue
from flights as f
join segments as s
on s.flight_id = f.flight_id
group by
f.flight_id,
f.scheduled_departure
having sum(s.price) > 15000000
order by total_revenue desc, f.flight_id;

-- Task 6
-- Output already departed or arrived flights
-- and the number of passengers actually boarded on them.

select
f.flight_id,
f.status,
count(bp.ticket_no) as boarded_passengers_count
from flights as f
left join boarding_passes as bp
on bp.flight_id = f.flight_id
where f.status in ('Departed', 'Arrived')
group by
f.flight_id,
f.status
order by f.flight_id;

-- Task 7
-- Find top-5 flights with maximum departure delay.

select
flight_id,
scheduled_departure,
actual_departure,
actual_departure - scheduled_departure as departure_delay
from flights
where actual_departure is not null
and actual_departure > scheduled_departure
order by departure_delay desc, flight_id
limit 5;

-- Task 8
-- Calculate occupancy percentage for each flight
-- for which boarding passes were issued.

with boarded as (
select
flight_id,
count(*) as boarded_passengers_count
from boarding_passes
group by flight_id
),
flight_seats as (
select
f.flight_id,
count(distinct s.seat_no) as total_seats
from flights as f
join routes as r
on r.route_no = f.route_no
join seats as s
on s.airplane_code = r.airplane_code
group by f.flight_id
)
select
b.flight_id,
b.boarded_passengers_count,
fs.total_seats,
round(
b.boarded_passengers_count::numeric * 100 / nullif(fs.total_seats, 0),
2
) as occupancy_percent
from boarded as b
join flight_seats as fs
on fs.flight_id = b.flight_id
order by occupancy_percent desc, b.flight_id;

-- Task 9
-- Determine average flight price for each route.
-- Output route number, departure airport code, arrival airport code
-- and calculated average price.

with route_prices as (
select
f.route_no,
avg(s.price) as average_flight_price
from flights as f
join segments as s
on s.flight_id = f.flight_id
group by f.route_no
),
route_info as (
select distinct
route_no,
departure_airport,
arrival_airport
from routes
)
select
ri.route_no,
ri.departure_airport,
ri.arrival_airport,
round(rp.average_flight_price, 2) as average_flight_price
from route_info as ri
join route_prices as rp
on rp.route_no = ri.route_no
order by ri.route_no;

-- Task 10
-- Output airports by the number of unique routes departing from them:
-- airport name, city and route count.

select
a.airport_name ->> 'ru' as airport_name_ru,
a.city ->> 'ru' as city_ru,
count(distinct r.route_no) as routes_count
from airports_data as a
join routes as r
on r.departure_airport = a.airport_code
group by
a.airport_code,
a.airport_name,
a.city
order by routes_count desc, airport_name_ru;

-- Task 11
-- Calculate what percentage of total flight revenue
-- comes from Business class tickets.
-- Output flight_id, total revenue, business revenue and calculated percentage.

select
flight_id,
sum(price) as total_revenue,
sum(
case
when fare_conditions = 'Business' then price
else 0
end
) as business_revenue,
round(
sum(
case
when fare_conditions = 'Business' then price
else 0
end
)::numeric * 100 / nullif(sum(price), 0),
2
) as business_revenue_percent
from segments
group by flight_id
order by business_revenue_percent desc, flight_id;

-- Task 12
-- Compare actual aircraft time in the air
-- with planned route duration.
-- Output flight_id, actual flight time and planned duration.

with route_duration as (
select distinct
route_no,
duration
from routes
)
select
f.flight_id,
f.actual_arrival - f.actual_departure as actual_flight_time,
rd.duration as planned_duration
from flights as f
join route_duration as rd
on rd.route_no = f.route_no
where f.actual_departure is not null
and f.actual_arrival is not null
order by f.flight_id;
