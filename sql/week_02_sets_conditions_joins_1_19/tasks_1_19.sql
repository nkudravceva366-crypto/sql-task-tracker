-- ==================================================
-- Week 02 — Sets, Conditions, Joins (1–19)
-- Educational airbase database
-- ==================================================

-- Task 1
-- Unique list of all airports involved in routes

select departure_airport as airport_code
from routes

union

select arrival_airport as airport_code
from routes
order by airport_code;


-- Task 2
-- Full event log: departures and arrivals

select
    flight_id,
    'Departure' as event_type,
    scheduled_departure as event_time
from flights

union all

select
    flight_id,
    'Arrival' as event_type,
    scheduled_arrival as event_time
from flights
order by event_time;


-- Task 3
-- Aircraft that have both Business and Comfort classes

select airplane_code
from seats
where fare_conditions in ('Business', 'Comfort')
group by airplane_code
having count(distinct fare_conditions) = 2
order by airplane_code;


-- Task 4
-- Free seats for flight_id = 1275

select s.seat_no
from seats s
join flights f
    on s.airplane_code = (
        select airplane_code
        from routes
        where route_no = f.route_no
    )
where f.flight_id = 1275
  and s.seat_no not in (
      select bp.seat_no
      from boarding_passes bp
      where bp.flight_id = 1275
  )
order by s.seat_no;


-- Task 5
-- Ticket direction: 'Туда' / 'Обратно'

select
    ticket_no,
    passenger_name,
    case
        when outbound = true then 'Туда'
        else 'Обратно'
    end as direction
from tickets
order by ticket_no;


-- Task 6
-- Aircraft category by flight range

select
    airplane_code,
    model ->> 'ru' as model_ru,
    case
        when range < 4000 then 'Ближнемагистральный'
        when range between 4000 and 8000 then 'Среднемагистральный'
        else 'Дальнемагистральный'
    end as range_category
from airplanes_data
order by range;


-- Task 7
-- Simplified flight status for recent departures

select
    flight_id,
    status,
    case
        when status in ('Scheduled', 'On Time', 'Delayed') then 'Ожидается'
        when status in ('Boarding', 'Departed') then 'В процессе'
        when status = 'Arrived' then 'Завершен'
        when status = 'Cancelled' then 'Отменен'
    end as simple_status,
    scheduled_departure
from flights
where scheduled_departure >= bookings.now() - interval '3 days'
order by scheduled_arrival desc;


-- Task 8
-- Flag potentially suspicious flight prices

select
    ticket_no,
    flight_id,
    fare_conditions,
    price,
    case
        when fare_conditions = 'Economy' and price > 50000
            then 'Подозрительно дорогой эконом'
        when fare_conditions = 'Business' and price < 15000
            then 'Подозрительно дешевый бизнес'
        else 'Норма'
    end as price_alert
from segments;


-- Task 9
-- Determine time of day by local departure time

select
    flight_id,
    scheduled_departure_local,
    case
        when extract(hour from scheduled_departure_local) between 6 and 11
            then 'Утро'
        when extract(hour from scheduled_departure_local) between 12 and 17
            then 'День'
        when extract(hour from scheduled_departure_local) between 18 and 23
            then 'Вечер'
        else 'Ночь'
    end as time_of_day
from timetable
order by scheduled_departure_local;


-- Task 10
-- Count flights by time of day

select
    time_of_day,
    count(*) as flights_count
from (
    select
        case
            when extract(hour from scheduled_departure_local) between 6 and 11
                then 'Утро'
            when extract(hour from scheduled_departure_local) between 12 and 17
                then 'День'
            when extract(hour from scheduled_departure_local) between 18 and 23
                then 'Вечер'
            else 'Ночь'
        end as time_of_day
    from timetable
) t
group by time_of_day
order by flights_count desc;


-- Task 11
-- Aircraft and number of seats

select
    a.airplane_code,
    a.model ->> 'ru' as model_ru,
    count(s.seat_no) as seats_count
from airplanes_data a
join seats s
    on a.airplane_code = s.airplane_code
group by a.airplane_code, a.model
order by seats_count desc;


-- Task 12
-- Expensive bookings over 900000 and passengers in them

select
    b.book_ref,
    b.book_date,
    b.total_amount,
    t.passenger_name
from bookings b
join tickets t
    on b.book_ref = t.book_ref
where b.total_amount > 900000
order by b.total_amount desc
limit 10;


-- Task 13
-- Route number, departure city and arrival city

select
    r.route_no,
    dep.city ->> 'ru' as departure_city,
    arr.city ->> 'ru' as arrival_city
from routes r
join airports_data dep
    on r.departure_airport = dep.airport_code
join airports_data arr
    on r.arrival_airport = arr.airport_code
order by r.route_no;


-- Task 14
-- Tickets, passengers and fare conditions for flight_id = 123

select
    s.ticket_no,
    t.passenger_name,
    s.fare_conditions
from flights f
join segments s
    on f.flight_id = s.flight_id
join tickets t
    on s.ticket_no = t.ticket_no
where f.flight_id = 123
order by s.ticket_no;


-- Task 15
-- Duplicate of Task 14. Solution is the same.


-- Task 16
-- Free seats for flight_id = 23405 using LEFT JOIN

select
    s.seat_no
from timetable t
join seats s
    on t.airplane_code = s.airplane_code
left join boarding_passes bp
    on bp.flight_id = t.flight_id
   and bp.seat_no = s.seat_no
where t.flight_id = 23405
  and bp.boarding_no is null
order by s.seat_no;


-- Task 17
-- Number of scheduled flights for each aircraft model

select
    a.model ->> 'ru' as model_ru,
    count(*) as flights_count
from flights f
join routes r
    on f.route_no = r.route_no
join airplanes_data a
    on r.airplane_code = a.airplane_code
group by a.model
order by flights_count desc;


-- Task 18
-- Duplicate of Task 16. Solution is the same.


-- Task 19
-- Full route sheet for ticket_no = '0005432000987'

select
    t.passenger_name,
    s.flight_id,
    f.scheduled_departure,
    dep.city ->> 'ru' as departure_city,
    arr.city ->> 'ru' as arrival_city
from tickets t
join segments s
    on t.ticket_no = s.ticket_no
join flights f
    on s.flight_id = f.flight_id
join routes r
    on f.route_no = r.route_no
join airports_data dep
    on r.departure_airport = dep.airport_code
join airports_data arr
    on r.arrival_airport = arr.airport_code
where t.ticket_no = '0005432000987'
order by f.scheduled_departure;
