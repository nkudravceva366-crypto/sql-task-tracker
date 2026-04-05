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


-- Task 8
-- First and last booking date

select
    min(book_date) as first_booking,
    max(book_date) as last_booking
from bookings;


-- Task 9
-- Number of airports in each time zone

select
    timezone,
    count(*) as airport_count
from airports_data
group by timezone
order by airport_count desc;


-- Task 10
-- Passengers whose names are shorter than 7 characters

select
    passenger_name,
    passenger_id
from tickets
where char_length(passenger_name) < 7
order by char_length(passenger_name), passenger_id
limit 10;


-- Task 11
-- Average ticket price without class breakdown

select
    round(avg(price::numeric), 2) as average_ticket_price
from segments;


-- Task 12
-- Average ticket price by fare class

select
    fare_conditions,
    round(avg(price::numeric), 2) as average_price
from segments
group by fare_conditions
order by average_price desc;


-- Task 13
-- Flights with revenue greater than 20,000,000

select
    flight_id,
    sum(price) as revenue
from segments
group by flight_id
having sum(price) > 20000000
order by revenue desc;


-- Task 14
-- Destination cities without duplicates

select distinct
    a.city->>'ru' as city
from routes r
join airports_data a
    on r.arrival_airport = a.airport_code
order by city;


-- Task 15
-- Count of flights in each status

select
    status,
    count(*) as flights_count
from flights
group by status
order by flights_count desc;


-- Task 16
-- Top 5 fastest aircraft

select
    airplane_code,
    model ->> 'ru' as model_ru,
    speed
from airplanes
order by speed desc, model_ru asc
limit 5;


-- Task 17
-- Total cost of all sold tickets through bookings

select
    sum(total_amount) as total_revenue
from bookings;


-- Task 18
-- Passenger name and document by ticket number

select
    passenger_name,
    passenger_id
from tickets
where ticket_no = '0005432000284';


-- Task 19
-- All possible fare_conditions from seats

select distinct
    fare_conditions
from seats
order by fare_conditions;


-- Task 20
-- Airports with timezone = Europe/Moscow

select
    airport_code,
    airport_name ->> 'ru' as name,
    city ->> 'ru' as city
from airports_data
where timezone = 'Europe/Moscow'
order by airport_code;


-- Task 21
-- All tickets and passenger names in booking KOS1KJ

select
    ticket_no,
    passenger_name
from tickets
where book_ref = 'KOS1KJ'
order by ticket_no;


-- Task 22
-- Top 5 routes with the greatest duration

select
    route_no,
    departure_airport,
    arrival_airport,
    duration
from routes
order by duration desc, route_no desc
limit 5;


-- Task 23
-- Top 12 airports by number of outgoing routes

select
    departure_airport,
    count(*) as routes_count
from routes
group by departure_airport
order by routes_count desc
limit 12;
