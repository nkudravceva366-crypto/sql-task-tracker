-- ==================================================
-- Week 05 — Views (1-3)
-- Educational airbase database
-- Schema: sandbox
-- Topics: CREATE VIEW, masked data, analytical views
-- ==================================================

-- Task 1
-- Create a view for airport employees.
-- It shows today's flight schedule:
-- flight_id, departure time, destination airport.
-- Passenger names are masked: only the first letter remains + stars.
-- Ticket price is masked as 0 with numeric data type.

create or replace view sandbox.kudravceva_v_today_flights_masked as
select
f.flight_id,
f.scheduled_departure as departure_time,
r.arrival_airport,
a.airport_name ->> 'ru' as arrival_airport_name_ru,
concat(left(t.passenger_name, 1), '***') as masked_passenger_name,
0::numeric as masked_price
from flights as f
join routes as r
on r.route_no = f.route_no
join airports_data as a
on a.airport_code = r.arrival_airport
join segments as s
on s.flight_id = f.flight_id
join tickets as t
on t.ticket_no = s.ticket_no
where f.scheduled_departure::date = current_date
order by f.scheduled_departure, f.flight_id;

-- Task 2
-- View: Financial report by routes.
-- Shows average sold ticket price and total revenue
-- for each unique route.

create or replace view sandbox.kudravceva_v_route_financial_report as
with route_info as (
select distinct
r.route_no,
r.departure_airport,
dep.city ->> 'ru' as departure_city_ru,
dep.airport_name ->> 'ru' as departure_airport_name_ru,
r.arrival_airport,
arr.city ->> 'ru' as arrival_city_ru,
arr.airport_name ->> 'ru' as arrival_airport_name_ru
from routes as r
join airports_data as dep
on dep.airport_code = r.departure_airport
join airports_data as arr
on arr.airport_code = r.arrival_airport
)
select
ri.route_no,
ri.departure_airport,
ri.departure_city_ru,
ri.departure_airport_name_ru,
ri.arrival_airport,
ri.arrival_city_ru,
ri.arrival_airport_name_ru,
round(avg(s.price), 2) as average_ticket_price,
sum(s.price) as total_revenue
from route_info as ri
join flights as f
on f.route_no = ri.route_no
join segments as s
on s.flight_id = f.flight_id
group by
ri.route_no,
ri.departure_airport,
ri.departure_city_ru,
ri.departure_airport_name_ru,
ri.arrival_airport,
ri.arrival_city_ru,
ri.arrival_airport_name_ru
order by ri.route_no;

-- Task 3
-- View: Price history for one seat.
-- Shows minimum, maximum and average ticket price
-- for a specific seat, for example seat 1A,
-- on aircraft model/code 7M7.

create or replace view sandbox.kudravceva_v_seat_price_history as
select
r.airplane_code,
ad.model ->> 'ru' as model_ru,
ad.model ->> 'en' as model_en,
bp.seat_no,
min(s.price) as min_ticket_price,
max(s.price) as max_ticket_price,
round(avg(s.price), 2) as avg_ticket_price
from boarding_passes as bp
join segments as s
on s.ticket_no = bp.ticket_no
and s.flight_id = bp.flight_id
join flights as f
on f.flight_id = s.flight_id
join routes as r
on r.route_no = f.route_no
join airplanes_data as ad
on ad.airplane_code = r.airplane_code
where r.airplane_code = '7M7'
and bp.seat_no = '1A'
group by
r.airplane_code,
ad.model,
bp.seat_no;

-- ==================================================
-- Cleanup commands after review and Done status:
-- run them only when created objects should be deleted.
-- ==================================================

-- drop view if exists sandbox.kudravceva_v_today_flights_masked;
-- drop view if exists sandbox.kudravceva_v_route_financial_report;
-- drop view if exists sandbox.kudravceva_v_seat_price_history;
