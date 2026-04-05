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


