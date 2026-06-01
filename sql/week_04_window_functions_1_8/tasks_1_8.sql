-- ==================================================
-- Week 04 — Window Functions (1-8)
-- Educational airbase database
-- Topics: running totals, ranking, LAG, ROW_NUMBER, moving averages
-- ==================================================

-- Task 1
-- Calculate running total of bookings revenue by day.
-- First aggregate revenue by day in CTE,
-- then apply a window function to the result.
-- Output first 10 rows.

with daily_revenue as (
select
book_date::date as booking_date,
sum(total_amount) as daily_total_amount
from bookings
group by book_date::date
)
select
booking_date,
sum(daily_total_amount) over (
order by booking_date
rows between unbounded preceding and current row
) as running_total_amount
from daily_revenue
order by booking_date
limit 10;

-- Task 2
-- Output flight_id, ticket_no and price.
-- For each flight, find three most expensive sold tickets.
-- If prices are equal, they share the same rank.

with ranked_tickets as (
select
flight_id,
ticket_no,
price,
dense_rank() over (
partition by flight_id
order by price desc
) as price_rank
from segments
)
select
flight_id,
ticket_no,
price
from ranked_tickets
where price_rank <= 3
order by flight_id, price desc, ticket_no;

-- Task 3
-- For each flight segment, output ticket price and average ticket price
-- within the same fare_conditions class.
-- Add the difference from average.
-- Remove duplicates using a window function.

with priced_segments as (
select
flight_id,
fare_conditions,
price,
round(
avg(price) over (
partition by fare_conditions
),
2
) as avg_class_price,
row_number() over (
partition by flight_id, fare_conditions, price
order by ticket_no
) as rn
from segments
)
select
flight_id,
fare_conditions,
price,
avg_class_price,
round(price - avg_class_price, 2) as diff_from_avg
from priced_segments
where rn = 1
order by flight_id, fare_conditions, price;

-- Task 4
-- For passenger Franklin Meyer, calculate how much time passed
-- between his previous and current flight.
-- Use LAG to access previous row.

with passenger_flights as (
select distinct
t.passenger_name,
f.flight_id,
f.scheduled_departure as departure_time
from tickets as t
join segments as s
on s.ticket_no = t.ticket_no
join flights as f
on f.flight_id = s.flight_id
where t.passenger_name = 'Franklin Meyer'
)
select
passenger_name,
flight_id,
departure_time,
departure_time - lag(departure_time) over (
partition by passenger_name
order by departure_time
) as time_since_last_flight
from passenger_flights
order by departure_time;

-- Task 5
-- Output booking number, booking date, booking amount
-- and percentage of this amount from total revenue on 2025-10-12.
-- Output 50 rows.

select
book_ref,
book_date,
total_amount,
round(
total_amount::numeric * 100 / nullif(sum(total_amount) over (), 0),
2
) as percent_from_daily_revenue
from bookings
where book_date::date = date '2025-10-12'
order by total_amount desc, book_ref
limit 50;

-- Task 6
-- In boarding_passes there is boarding_no,
-- but imagine it does not exist.
-- Assign passenger numbers manually by boarding_time
-- inside flight 15.

select
flight_id,
ticket_no,
boarding_time,
row_number() over (
partition by flight_id
order by boarding_time, ticket_no
) as generated_boarding_no
from boarding_passes
where flight_id = 15
order by generated_boarding_no;

-- Task 7
-- Find the first morning departure from airport AER for each day.
-- Output dep_date, airport code, flight_id and departure time.

with aer_flights as (
select
f.scheduled_departure::date as dep_date,
r.departure_airport,
f.flight_id,
f.scheduled_departure as departure_time,
row_number() over (
partition by f.scheduled_departure::date
order by f.scheduled_departure, f.flight_id
) as rn
from flights as f
join (
select distinct
route_no,
departure_airport
from routes
) as r
on r.route_no = f.route_no
where r.departure_airport = 'AER'
and f.scheduled_departure::time < time '12:00'
)
select
dep_date,
departure_airport,
flight_id,
departure_time
from aer_flights
where rn = 1
order by dep_date;

-- Task 8
-- Calculate moving average of bookings revenue
-- for the current day and two previous days.

with daily_revenue as (
select
book_date::date as booking_date,
sum(total_amount) as daily_total_amount
from bookings
group by book_date::date
)
select
booking_date,
daily_total_amount,
round(
avg(daily_total_amount) over (
order by booking_date
rows between 2 preceding and current row
),
2
) as moving_avg_3_days
from daily_revenue
order by booking_date;
