-- ==================================================
-- Week 01 — Airbase SQL Tasks (1–23)
-- Educational airbase database
-- ==================================================

-- Task 1
-- Aircraft models with range greater than 5000

select
    model->>'en' as model_en,
    range
from airplanes_data
where range > 5000
order by range desc;


-- Task 2
-- Number of aircraft with range less than 4000

select
    count(*) as airplanes_count
from airplanes_data
where range < 4000;


-- Task 3
-- Cancelled flights

select
    flight_id,
    route_no
from flights
where status = 'Cancelled'
order by flight_id
limit 10;


-- Task 4
-- Airports located in Moscow

select
    airport_code,
    airport_name->>'ru' as ru_airport_name,
    airport_name->>'en' as en_airport_name
from airports_data
where city->>'ru' = 'Москва'
order by airport_code;


-- Task 5
-- Number of business class seats in aircraft 32N

select
    count(*) as business_seats_count
from seats
where airplane_code = '32N'
  and fare_conditions = 'Business';


-- Task 6
-- Five cheapest bookings

select
    book_ref,
    total_amount,
    book_date
from bookings
order by total_amount
limit 5;


-- Task 7
-- Aircraft of model "Боинг"

select
    airplane_code,
    model->>'ru' as model_ru
from airplanes_data
where model->>'ru' like '%Боинг%';
