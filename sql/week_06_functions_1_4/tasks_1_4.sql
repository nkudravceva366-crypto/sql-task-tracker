-- ==================================================
-- Week 06 — Functions (1-4)
-- Educational airbase database
-- Schema: sandbox
-- Topics: CREATE FUNCTION, parameters, CASE, RETURN TABLE
-- ==================================================

-- ==================================================
-- Task 1
-- By passenger_id determine client grade based on total money spent
-- during the whole history.
----------------------------

-- Grades:
-- Standard: 0 <= total_spent < 50,000
-- Silver: 50,000 <= total_spent < 150,000
-- Gold: 150,000 <= total_spent <= 300,000
-- Platinum: total_spent > 300,000
----------------------------------

-- Test clients:
-- US 2976063125423
-- SE 6854068682151
-- ==================================================

create or replace function sandbox.kudravceva_f_client_grade(
p_passenger_id varchar
)
returns table (
passenger_id varchar,
passenger_name text,
total_spent numeric,
client_grade text
)
language sql
as $$
select
t.passenger_id,
max(t.passenger_name) as passenger_name,
coalesce(sum(s.price), 0)::numeric as total_spent,
case
when coalesce(sum(s.price), 0) < 50000 then 'Standard'
when coalesce(sum(s.price), 0) < 150000 then 'Silver'
when coalesce(sum(s.price), 0) <= 300000 then 'Gold'
else 'Platinum'
end as client_grade
from tickets as t
left join segments as s
on s.ticket_no = t.ticket_no
where t.passenger_id = p_passenger_id
group by t.passenger_id;
$$;

-- Result calls for Task 1

select *
from sandbox.kudravceva_f_client_grade('US 2976063125423');

select *
from sandbox.kudravceva_f_client_grade('SE 6854068682151');

-- ==================================================
-- Task 2
-- Passenger wants to return a ticket.
-- The closer the departure date, the bigger the penalty.
---------------------------------------------------------

## -- Function receives ticket_no and returns refund amount.

-- Rules:
-- If departure is today: refund = 0
-- If 1 <= days before departure < 3: penalty 70%, refund 30%
-- If 3 <= days before departure < 14: penalty 30%, refund 70%
-- If days before departure >= 14: full refund
----------------------------------------------

-- Test tickets:
-- 0005453191978
-- 0005452344109
-- 0005451639590
-- 0005451677213
-- ==================================================

create or replace function sandbox.kudravceva_f_ticket_refund(
p_ticket_no varchar
)
returns table (
ticket_no varchar,
total_ticket_price numeric,
nearest_departure timestamp,
days_before_departure integer,
refund_amount numeric
)
language sql
as $$
with ticket_info as (
select
s.ticket_no,
sum(s.price)::numeric as total_ticket_price,
min(f.scheduled_departure) as nearest_departure
from segments as s
join flights as f
on f.flight_id = s.flight_id
where s.ticket_no = p_ticket_no
group by s.ticket_no
)
select
ti.ticket_no,
ti.total_ticket_price,
ti.nearest_departure,
(ti.nearest_departure::date - current_date)::integer as days_before_departure,
round(
case
when (ti.nearest_departure::date - current_date)::integer <= 0
then 0
when (ti.nearest_departure::date - current_date)::integer >= 1
and (ti.nearest_departure::date - current_date)::integer < 3
then ti.total_ticket_price * 0.30
when (ti.nearest_departure::date - current_date)::integer >= 3
and (ti.nearest_departure::date - current_date)::integer < 14
then ti.total_ticket_price * 0.70
else ti.total_ticket_price
end,
2
) as refund_amount
from ticket_info as ti;
$$;

-- Result calls for Task 2

select *
from sandbox.kudravceva_f_ticket_refund('0005453191978');

select *
from sandbox.kudravceva_f_ticket_refund('0005452344109');

select *
from sandbox.kudravceva_f_ticket_refund('0005451639590');

select *
from sandbox.kudravceva_f_ticket_refund('0005451677213');

-- ==================================================
-- Task 3
-- API request:
-- How many free seats of a given class are left on a given flight?
-------------------------------------------------------------------

## -- Function receives flight_id and fare_conditions.

-- Test parameters:
-- 124968, Business
-- 124977, Economy
-- 125244, Business
-- ==================================================

create or replace function sandbox.kudravceva_f_free_seats(
p_flight_id integer,
p_fare_conditions varchar
)
returns table (
flight_id integer,
fare_conditions varchar,
total_seats integer,
occupied_seats integer,
free_seats integer
)
language sql
as $$
with flight_airplane as (
select distinct
f.flight_id,
r.airplane_code
from flights as f
join routes as r
on r.route_no = f.route_no
where f.flight_id = p_flight_id
),
total_class_seats as (
select
fa.flight_id,
count(*)::integer as total_seats
from flight_airplane as fa
join seats as st
on st.airplane_code = fa.airplane_code
where st.fare_conditions = p_fare_conditions
group by fa.flight_id
),
occupied_class_seats as (
select
bp.flight_id,
count(*)::integer as occupied_seats
from boarding_passes as bp
join flight_airplane as fa
on fa.flight_id = bp.flight_id
join seats as st
on st.airplane_code = fa.airplane_code
and st.seat_no = bp.seat_no
where bp.flight_id = p_flight_id
and st.fare_conditions = p_fare_conditions
group by bp.flight_id
)
select
tcs.flight_id,
p_fare_conditions as fare_conditions,
tcs.total_seats,
coalesce(ocs.occupied_seats, 0) as occupied_seats,
tcs.total_seats - coalesce(ocs.occupied_seats, 0) as free_seats
from total_class_seats as tcs
left join occupied_class_seats as ocs
on ocs.flight_id = tcs.flight_id;
$$;

-- Result calls for Task 3

select *
from sandbox.kudravceva_f_free_seats(124968, 'Business');

select *
from sandbox.kudravceva_f_free_seats(124977, 'Economy');

select *
from sandbox.kudravceva_f_free_seats(125244, 'Business');

-- ==================================================
-- Task 4
-- Flight attendant needs a list of all passengers
-- for a specific flight with their seats.
------------------------------------------

## -- Function receives flight_id and returns a table.

-- Test flights:
-- 1663
-- 854
-- ==================================================

create or replace function sandbox.kudravceva_f_flight_passengers(
p_flight_id integer
)
returns table (
flight_id integer,
ticket_no varchar,
passenger_id varchar,
passenger_name text,
fare_conditions varchar,
seat_no varchar,
boarding_no integer
)
language sql
as $$
select
s.flight_id,
t.ticket_no,
t.passenger_id,
t.passenger_name,
s.fare_conditions,
bp.seat_no,
bp.boarding_no
from segments as s
join tickets as t
on t.ticket_no = s.ticket_no
left join boarding_passes as bp
on bp.ticket_no = s.ticket_no
and bp.flight_id = s.flight_id
where s.flight_id = p_flight_id
order by
bp.boarding_no nulls last,
t.passenger_name,
t.ticket_no;
$$;

-- Result calls for Task 4

select *
from sandbox.kudravceva_f_flight_passengers(1663);

select *
from sandbox.kudravceva_f_flight_passengers(854);

-- ==================================================
-- Cleanup commands after review and Done status:
-- run them only when created objects should be deleted.
-- ==================================================

-- drop function if exists sandbox.kudravceva_f_client_grade(varchar);
-- drop function if exists sandbox.kudravceva_f_ticket_refund(varchar);
-- drop function if exists sandbox.kudravceva_f_free_seats(integer, varchar);
-- drop function if exists sandbox.kudravceva_f_flight_passengers(integer);
