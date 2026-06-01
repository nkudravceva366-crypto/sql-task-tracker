-- ==================================================
-- Week 08 — Procedures (1)
-- Educational airbase database
-- Schema: sandbox
-- Topics: CREATE PROCEDURE, batch loading, local analytical storage
-- ==================================================

-- ==================================================
-- Task 1
-- Design local storage for a new regional hub
-- and create a procedure that loads historical data
-- from the central demo database in daily batches.
---------------------------------------------------

-- Main idea:
-- Central schema bookings contains historical data about flights,
-- airplanes and tickets. Loading all data at once may be too heavy,
-- so data is loaded by one flight day and one hub airport.
-----------------------------------------------------------

-- Local analytical storage consists of:
-- 1) sandbox.kudravceva_hub_flights
--    flight-level data for the regional hub;
---------------------------------------------

-- 2) sandbox.kudravceva_hub_tickets
--    ticket/passenger/seat-level data for loaded flights;
----------------------------------------------------------

-- 3) sandbox.kudravceva_hub_load_log
--    load log with number of inserted rows and load timestamp.
---------------------------------------------------------------

-- Procedure:
-- sandbox.kudravceva_p_load_hub_day(p_load_date, p_hub_airport_code)
---------------------------------------------------------------------

-- It loads flights for one day where the hub airport is either
-- departure_airport or arrival_airport.
-- ==================================================

---

-- 1. Local storage: flights for regional hub

---

create table if not exists sandbox.kudravceva_hub_flights (
load_date date not null,
hub_airport_code varchar(3) not null,

```
flight_id integer primary key,
route_no integer,
flight_date date,

departure_airport varchar(3),
departure_airport_name_ru text,
departure_city_ru text,

arrival_airport varchar(3),
arrival_airport_name_ru text,
arrival_city_ru text,

airplane_code varchar(3),
airplane_model_ru text,

status varchar(20),
scheduled_departure timestamp with time zone,
scheduled_arrival timestamp with time zone,
actual_departure timestamp with time zone,
actual_arrival timestamp with time zone,

loaded_at timestamp with time zone default now()
```

);

---

-- 2. Local storage: tickets/passengers for loaded flights

---

create table if not exists sandbox.kudravceva_hub_tickets (
load_date date not null,
hub_airport_code varchar(3) not null,

```
flight_id integer not null,
ticket_no varchar(20) not null,
book_ref varchar(20),

passenger_id varchar(30),
passenger_name text,

fare_conditions varchar(20),
price numeric,

seat_no varchar(10),
boarding_no integer,
boarding_time timestamp with time zone,

book_date timestamp with time zone,
booking_total_amount numeric,

loaded_at timestamp with time zone default now(),

constraint kudravceva_hub_tickets_pk
    primary key (flight_id, ticket_no)
```

);

---

-- 3. Local storage: batch load log

---

create table if not exists sandbox.kudravceva_hub_load_log (
load_date date not null,
hub_airport_code varchar(3) not null,

```
flights_inserted integer not null,
ticket_rows_inserted integer not null,

loaded_at timestamp with time zone default now(),

constraint kudravceva_hub_load_log_pk
    primary key (load_date, hub_airport_code)
```

);

---

-- 4. Procedure for daily batch loading

---

create or replace procedure sandbox.kudravceva_p_load_hub_day(
p_load_date date,
p_hub_airport_code varchar
)
language plpgsql
as $$
declare
v_hub_airport_code varchar(3);
v_flights_inserted integer := 0;
v_ticket_rows_inserted integer := 0;
begin
v_hub_airport_code := upper(p_hub_airport_code);

```
if p_load_date is null then
    raise exception 'p_load_date must not be null';
end if;

if p_hub_airport_code is null or length(trim(p_hub_airport_code)) = 0 then
    raise exception 'p_hub_airport_code must not be null or empty';
end if;

-- Idempotent reload for the same day and hub:
-- first delete previous batch data, then insert fresh data.
delete from sandbox.kudravceva_hub_tickets ht
using sandbox.kudravceva_hub_flights hf
where ht.flight_id = hf.flight_id
  and hf.load_date = p_load_date
  and hf.hub_airport_code = v_hub_airport_code;

delete from sandbox.kudravceva_hub_flights
where load_date = p_load_date
  and hub_airport_code = v_hub_airport_code;

-- Load flight-level data for one day and one regional hub.
insert into sandbox.kudravceva_hub_flights (
    load_date,
    hub_airport_code,
    flight_id,
    route_no,
    flight_date,
    departure_airport,
    departure_airport_name_ru,
    departure_city_ru,
    arrival_airport,
    arrival_airport_name_ru,
    arrival_city_ru,
    airplane_code,
    airplane_model_ru,
    status,
    scheduled_departure,
    scheduled_arrival,
    actual_departure,
    actual_arrival
)
select
    p_load_date as load_date,
    v_hub_airport_code as hub_airport_code,

    f.flight_id,
    f.route_no,
    f.scheduled_departure::date as flight_date,

    r.departure_airport,
    dep.airport_name ->> 'ru' as departure_airport_name_ru,
    dep.city ->> 'ru' as departure_city_ru,

    r.arrival_airport,
    arr.airport_name ->> 'ru' as arrival_airport_name_ru,
    arr.city ->> 'ru' as arrival_city_ru,

    r.airplane_code,
    ad.model ->> 'ru' as airplane_model_ru,

    f.status,
    f.scheduled_departure,
    f.scheduled_arrival,
    f.actual_departure,
    f.actual_arrival
from bookings.flights as f
join bookings.routes as r
    on r.route_no = f.route_no
   and r.validity @> f.scheduled_departure
join bookings.airports_data as dep
    on dep.airport_code = r.departure_airport
join bookings.airports_data as arr
    on arr.airport_code = r.arrival_airport
join bookings.airplanes_data as ad
    on ad.airplane_code = r.airplane_code
where f.scheduled_departure::date = p_load_date
  and (
        r.departure_airport = v_hub_airport_code
     or r.arrival_airport = v_hub_airport_code
  );

get diagnostics v_flights_inserted = row_count;

-- Load ticket/passenger/seat-level data for already loaded flights.
insert into sandbox.kudravceva_hub_tickets (
    load_date,
    hub_airport_code,
    flight_id,
    ticket_no,
    book_ref,
    passenger_id,
    passenger_name,
    fare_conditions,
    price,
    seat_no,
    boarding_no,
    boarding_time,
    book_date,
    booking_total_amount
)
select
    p_load_date as load_date,
    v_hub_airport_code as hub_airport_code,

    s.flight_id,
    t.ticket_no,
    t.book_ref,

    t.passenger_id,
    t.passenger_name,

    s.fare_conditions,
    s.price,

    bp.seat_no,
    bp.boarding_no,
    bp.boarding_time,

    b.book_date,
    b.total_amount as booking_total_amount
from sandbox.kudravceva_hub_flights as hf
join bookings.segments as s
    on s.flight_id = hf.flight_id
join bookings.tickets as t
    on t.ticket_no = s.ticket_no
join bookings.bookings as b
    on b.book_ref = t.book_ref
left join bookings.boarding_passes as bp
    on bp.ticket_no = s.ticket_no
   and bp.flight_id = s.flight_id
where hf.load_date = p_load_date
  and hf.hub_airport_code = v_hub_airport_code;

get diagnostics v_ticket_rows_inserted = row_count;

-- Save batch loading result.
insert into sandbox.kudravceva_hub_load_log (
    load_date,
    hub_airport_code,
    flights_inserted,
    ticket_rows_inserted,
    loaded_at
)
values (
    p_load_date,
    v_hub_airport_code,
    v_flights_inserted,
    v_ticket_rows_inserted,
    now()
)
on conflict (load_date, hub_airport_code)
do update set
    flights_inserted = excluded.flights_inserted,
    ticket_rows_inserted = excluded.ticket_rows_inserted,
    loaded_at = excluded.loaded_at;

raise notice
    'Loaded data for date %, hub %. Flights: %, ticket rows: %',
    p_load_date,
    v_hub_airport_code,
    v_flights_inserted,
    v_ticket_rows_inserted;
```

end;
$$;

---

-- 5. Example procedure calls and result checks

---

call sandbox.kudravceva_p_load_hub_day(date '2025-10-12', 'AER');

-- Check load log

select
load_date,
hub_airport_code,
flights_inserted,
ticket_rows_inserted,
loaded_at
from sandbox.kudravceva_hub_load_log
where load_date = date '2025-10-12'
and hub_airport_code = 'AER';

-- Check loaded flights

select
flight_id,
route_no,
flight_date,
departure_airport,
arrival_airport,
airplane_code,
status
from sandbox.kudravceva_hub_flights
where load_date = date '2025-10-12'
and hub_airport_code = 'AER'
order by flight_id
limit 20;

-- Check loaded ticket/passenger rows

select
flight_id,
ticket_no,
passenger_id,
passenger_name,
fare_conditions,
price,
seat_no,
boarding_no
from sandbox.kudravceva_hub_tickets
where load_date = date '2025-10-12'
and hub_airport_code = 'AER'
order by flight_id, ticket_no
limit 20;

---

-- 6. Cleanup commands after review and Done status
-- Run them only when created objects should be deleted.

---

-- drop procedure if exists sandbox.kudravceva_p_load_hub_day(date, varchar);
-- drop table if exists sandbox.kudravceva_hub_tickets;
-- drop table if exists sandbox.kudravceva_hub_flights;
-- drop table if exists sandbox.kudravceva_hub_load_log;
