-- ==================================================
-- Week 07 — Query Optimization (1-2)
-- Educational airbase database
-- Topics: query documentation, execution plan analysis, optimization proposals
-- ==================================================

-- ==================================================
-- Task 1
-- Long analytical query documentation and optimization ideas
-- ==================================================

---

-- 1. Business purpose of the report

---

-- This report is intended to find flights that look commercially interesting:
-- they sold less than half of all available seats, but their revenue is higher
-- than the average revenue for the same route.
-----------------------------------------------

-- In business terms, the report highlights flights with:
-- 1) low load factor;
-- 2) high revenue compared to other flights on the same route.
---------------------------------------------------------------

-- Such flights may be useful for revenue management analysis:
-- - checking pricing strategy;
-- - identifying routes where Business/Comfort tickets may strongly affect revenue;
-- - finding flights with expensive tickets but low occupancy;
-- - analyzing whether capacity is used efficiently.

---

-- 2. Original query

---

explain (analyze, buffers, verbose)
with flight_metrics as (
select
f.flight_id,
f.route_no,
date(f.scheduled_departure) as flight_date,
r.airplane_code,
count(s.ticket_no) as sold_tickets,
sum(s.price) as total_revenue
from bookings.flights f
join bookings.routes r
on f.route_no = r.route_no
and r.validity @> f.scheduled_departure
join bookings.segments s
on f.flight_id = s.flight_id
where f.status in ('Departed', 'Arrived')
group by
f.flight_id,
f.route_no,
date(f.scheduled_departure),
r.airplane_code
),
advanced_metrics as (
select
fm.flight_id,
fm.route_no,
fm.flight_date,
fm.sold_tickets,
fm.total_revenue,
avg(fm.total_revenue) over (
partition by fm.route_no
) as avg_route_revenue,
(
select count(*)
from bookings.seats st
where st.airplane_code = fm.airplane_code
) as max_seats
from flight_metrics fm
)
select
flight_id,
route_no,
flight_date,
sold_tickets,
max_seats,
round(sold_tickets::numeric / max_seats * 100, 1) as load_factor_percent,
total_revenue,
round(avg_route_revenue, 2) as avg_route_revenue
from advanced_metrics
where
sold_tickets < (max_seats / 2)
and total_revenue > avg_route_revenue
order by
total_revenue desc;

---

-- 3. Query documentation

---

-- CTE flight_metrics:
-- This block calculates metrics at the flight level.
-----------------------------------------------------

-- f.flight_id:
-- Unique flight identifier.
----------------------------

-- f.route_no:
-- Route number for the flight.
-------------------------------

-- date(f.scheduled_departure) as flight_date:
-- Converts scheduled departure timestamp to date.
-- This allows the report to show the flight day without time.
--------------------------------------------------------------

-- r.airplane_code:
-- Aircraft code used on this route at the moment of scheduled departure.
-------------------------------------------------------------------------

-- count(s.ticket_no) as sold_tickets:
-- Counts sold flight segments/tickets for the flight.
-- In this schema, table segments connects tickets with flights.
----------------------------------------------------------------

-- sum(s.price) as total_revenue:
-- Calculates total flight revenue based on sold ticket segment prices.
-----------------------------------------------------------------------

-- join bookings.routes r:
-- Connects each flight with its route.
-- The additional condition r.validity @> f.scheduled_departure
-- selects the route version that was valid at the time of the flight.
----------------------------------------------------------------------

-- join bookings.segments s:
-- Connects flights with sold ticket segments.
----------------------------------------------

-- where f.status in ('Departed', 'Arrived'):
-- Leaves only flights that have already departed or arrived.
-- Future, scheduled or cancelled flights are excluded.
-------------------------------------------------------

-- group by:
-- Aggregates data to one row per flight/route/date/aircraft combination.
-------------------------------------------------------------------------

--
-- CTE advanced_metrics:
-- This block adds route-level and aircraft-level metrics.
----------------------------------------------------------

-- avg(fm.total_revenue) over (partition by fm.route_no):
-- Calculates average flight revenue inside each route.
-- This is a window function: it does not collapse rows,
-- but adds the route average to every flight row.
--------------------------------------------------

-- Scalar subquery for max_seats:
-- Counts all seats for the aircraft used on the flight.
-- This value is used as maximum aircraft capacity.
---------------------------------------------------

--
-- Final SELECT:
-- flight_id, route_no, flight_date:
-- Main flight identifiers.
---------------------------

-- sold_tickets:
-- Number of sold ticket segments for this flight.
--------------------------------------------------

-- max_seats:
-- Total number of seats in the aircraft.
-----------------------------------------

-- load_factor_percent:
-- Percentage of occupied/sold seats:
-- sold_tickets / max_seats * 100.
----------------------------------

-- total_revenue:
-- Total revenue for the flight.
--------------------------------

-- avg_route_revenue:
-- Average revenue for all selected flights of the same route.
--------------------------------------------------------------

-- WHERE condition:
-- sold_tickets < max_seats / 2
-- keeps flights where less than half of the seats were sold.
-------------------------------------------------------------

-- total_revenue > avg_route_revenue
-- keeps flights where revenue is higher than average revenue for this route.
-----------------------------------------------------------------------------

-- ORDER BY total_revenue DESC:
-- Shows the most profitable matching flights first.

---

-- 4. Expected execution plan explanation

---

-- The exact plan depends on PostgreSQL statistics, indexes and data volume.
-- After running EXPLAIN (ANALYZE, BUFFERS, VERBOSE), the plan should be read
-- from bottom to top.
----------------------

## -- Possible plan nodes and their meaning:

-- Seq Scan on flights:
-- PostgreSQL reads rows from flights and applies the filter
-- status IN ('Departed', 'Arrived').
-- If many rows are filtered out, a partial index by status may help.
---------------------------------------------------------------------

-- Join between flights and routes:
-- The database matches flights with route versions by route_no
-- and validity range condition:
-- r.validity @> f.scheduled_departure.
-- This condition may be expensive if there is no suitable index
-- for route_no and/or validity.
--------------------------------

-- Join between flights and segments:
-- The database joins sold ticket segments to flights by flight_id.
-- If segments is large, an index on segments(flight_id) may be important.
--------------------------------------------------------------------------

-- HashAggregate or GroupAggregate:
-- The database groups rows by flight_id, route_no, flight_date and airplane_code
-- to calculate sold_tickets and total_revenue.
-----------------------------------------------

-- WindowAgg:
-- The database calculates avg(total_revenue) over each route_no.
-- This may require sorting or hashing by route_no.
---------------------------------------------------

-- SubPlan / Scalar Subquery for seats:
-- For each row from flight_metrics, PostgreSQL may execute a subquery
-- that counts seats by airplane_code.
-- This can be inefficient if repeated many times.
--------------------------------------------------

-- Sort:
-- The final result is sorted by total_revenue DESC.
-- If the result set is large, sorting may consume memory.
----------------------------------------------------------

-- Buffers:
-- The BUFFERS section shows how many pages were read from cache or disk.
-- High disk reads may indicate missing indexes, large scans or insufficient cache.

---

-- 5. Optimization ideas without actual implementation

---

-- Idea 1:
-- Precalculate aircraft seat capacity once and join it instead of using
-- a scalar subquery for every row.
-----------------------------------

-- Current logic:
-- (
--     select count(*)
--     from bookings.seats st
--     where st.airplane_code = fm.airplane_code
-- ) as max_seats
-----------------

-- Better idea:
-- create a separate CTE seats_by_airplane:
-------------------------------------------

-- with seats_by_airplane as (
--     select airplane_code, count(*) as max_seats
--     from bookings.seats
--     group by airplane_code
-- )
----

-- Then join seats_by_airplane to flight_metrics by airplane_code.
-- This avoids repeated counting for every flight row.
------------------------------------------------------

--
-- Idea 2:
-- Check indexes for join and filter columns:
-- - bookings.flights(status)
-- - bookings.flights(route_no, scheduled_departure)
-- - bookings.segments(flight_id)
-- - bookings.routes(route_no)
-- - bookings.seats(airplane_code)
----------------------------------

-- For the range condition r.validity @> f.scheduled_departure,
-- a GiST index on routes.validity may be useful.
-------------------------------------------------

--
-- Idea 3:
-- If this report is used often, consider creating an analytical view
-- or materialized view with flight-level metrics:
-- flight_id, route_no, flight_date, airplane_code, sold_tickets, total_revenue.
-- Then the final report would work with pre-aggregated data.
-------------------------------------------------------------

--
-- Idea 4:
-- Make sure table statistics are up to date.
-- PostgreSQL optimizer relies on statistics.
---------------------------------------------

-- analyze bookings.flights;
-- analyze bookings.routes;
-- analyze bookings.segments;
-- analyze bookings.seats;

---

-- 6. Possible optimized query shape
-- This is only a proposed rewrite, not actual implementation requirement.

---

-- The main optimization idea is to replace repeated scalar subquery
-- with one grouped CTE for aircraft capacity.

-- with seats_by_airplane as (
--     select
--         airplane_code,
--         count(*) as max_seats
--     from bookings.seats
--     group by airplane_code
-- ),
-- flight_metrics as (
--     select
--         f.flight_id,
--         f.route_no,
--         date(f.scheduled_departure) as flight_date,
--         r.airplane_code,
--         count(s.ticket_no) as sold_tickets,
--         sum(s.price) as total_revenue
--     from bookings.flights f
--     join bookings.routes r
--         on f.route_no = r.route_no
--        and r.validity @> f.scheduled_departure
--     join bookings.segments s
--         on f.flight_id = s.flight_id
--     where f.status in ('Departed', 'Arrived')
--     group by
--         f.flight_id,
--         f.route_no,
--         date(f.scheduled_departure),
--         r.airplane_code
-- ),
-- advanced_metrics as (
--     select
--         fm.flight_id,
--         fm.route_no,
--         fm.flight_date,
--         fm.sold_tickets,
--         fm.total_revenue,
--         avg(fm.total_revenue) over (
--             partition by fm.route_no
--         ) as avg_route_revenue,
--         sba.max_seats
--     from flight_metrics fm
--     join seats_by_airplane sba
--         on sba.airplane_code = fm.airplane_code
-- )
-- select
--     flight_id,
--     route_no,
--     flight_date,
--     sold_tickets,
--     max_seats,
--     round(sold_tickets::numeric / max_seats * 100, 1) as load_factor_percent,
--     total_revenue,
--     round(avg_route_revenue, 2) as avg_route_revenue
-- from advanced_metrics
-- where
--     sold_tickets < (max_seats / 2)
--     and total_revenue > avg_route_revenue
-- order by
--     total_revenue desc;

-- ==================================================
-- Task 2
-- Three proposals for optimizing data storage
-- in the airbase database
-- ==================================================

---

-- Proposal 1
-- Add/check indexes for frequent joins and filters

---

-- Reason:
-- Many analytical queries join flights with segments by flight_id,
-- flights with routes by route_no, and filter flights by status/date.
-- Without suitable indexes PostgreSQL may use sequential scans
-- and expensive joins on large tables.
---------------------------------------

-- What to measure before implementation:
-- Run EXPLAIN (ANALYZE, BUFFERS) for typical queries and check:
-- - whether Seq Scan appears on large tables;
-- - how many rows are removed by filters;
-- - how many buffers are read;
-- - actual execution time.
---------------------------

-- Diagnostic example:

explain (analyze, buffers)
select
f.flight_id,
count(s.ticket_no) as sold_tickets,
sum(s.price) as total_revenue
from bookings.flights f
join bookings.segments s
on s.flight_id = f.flight_id
where f.status in ('Departed', 'Arrived')
group by f.flight_id;

-- Possible index candidates, not implemented here:
-- create index idx_flights_status_route_departure
--     on bookings.flights(status, route_no, scheduled_departure);
------------------------------------------------------------------

-- create index idx_segments_flight_id
--     on bookings.segments(flight_id);
---------------------------------------

-- create index idx_routes_route_no
--     on bookings.routes(route_no);

---

-- Proposal 2
-- Consider partitioning large historical tables by date

---

-- Reason:
-- Tables such as bookings and flights contain time-based data.
-- Analytical reports often filter by booking date, departure date,
-- month, quarter or year.
-- If the tables become large, partitioning by date can reduce
-- the amount of data scanned by queries.
-----------------------------------------

-- Example candidates:
-- - bookings by book_date;
-- - flights by scheduled_departure.
------------------------------------

-- What to measure before implementation:
-- - table size;
-- - most common date filters;
-- - execution plans for date-filtered reports;
-- - whether PostgreSQL scans the whole table for a small date range.
---------------------------------------------------------------------

-- Diagnostic examples:

select
schemaname,
relname,
pg_size_pretty(
pg_total_relation_size(format('%I.%I', schemaname, relname)::regclass)
) as total_size
from pg_stat_user_tables
where schemaname = 'bookings'
and relname in ('bookings', 'flights', 'segments')
order by pg_total_relation_size(format('%I.%I', schemaname, relname)::regclass) desc;

explain (analyze, buffers)
select
book_date::date as booking_date,
sum(total_amount) as revenue
from bookings.bookings
where book_date >= date '2025-10-01'
and book_date < date '2025-11-01'
group by book_date::date;

-- Possible future solution:
-- Use range partitioning by month or year for large historical tables.
-- This should only be implemented after checking data volume,
-- query patterns and maintenance cost.

---

-- Proposal 3
-- Create pre-aggregated analytical storage for frequent reports

---

-- Reason:
-- Some reports repeatedly calculate the same metrics:
-- revenue by flight, revenue by route, sold tickets,
-- load factor, daily booking revenue.
-- Recomputing these metrics from raw tables every time may be expensive.
-------------------------------------------------------------------------

-- A good storage optimization approach is to keep raw normalized data,
-- but add a pre-aggregated layer for analytics.
------------------------------------------------

-- Possible options:
-- - materialized views;
-- - summary tables refreshed by schedule;
-- - reporting schema with precomputed metrics.
-----------------------------------------------

-- What to measure before implementation:
-- - frequency of report execution;
-- - execution time of raw query;
-- - cost of refresh;
-- - acceptable data freshness;
-- - storage overhead.
----------------------

-- Diagnostic example:

explain (analyze, buffers)
select
f.route_no,
date(f.scheduled_departure) as flight_date,
count(s.ticket_no) as sold_tickets,
sum(s.price) as total_revenue
from bookings.flights f
join bookings.segments s
on s.flight_id = f.flight_id
where f.status in ('Departed', 'Arrived')
group by
f.route_no,
date(f.scheduled_departure);

-- Possible future solution, not implemented here:
-- create materialized view sandbox.kudravceva_mv_flight_revenue_daily as
-- select
--     f.route_no,
--     date(f.scheduled_departure) as flight_date,
--     count(s.ticket_no) as sold_tickets,
--     sum(s.price) as total_revenue
-- from bookings.flights f
-- join bookings.segments s
--     on s.flight_id = f.flight_id
-- where f.status in ('Departed', 'Arrived')
-- group by
--     f.route_no,
--     date(f.scheduled_departure);
-----------------------------------

-- refresh materialized view sandbox.kudravceva_mv_flight_revenue_daily;

-- ==================================================
-- Final summary
-- ==================================================
-- The main optimization direction for the long report:
-- 1) document business meaning and query logic;
-- 2) analyze the actual execution plan with EXPLAIN ANALYZE;
-- 3) remove repeated scalar subquery for seat count;
-- 4) check indexes for joins, filters and range condition;
-- 5) consider pre-aggregated storage for frequently used reports.
