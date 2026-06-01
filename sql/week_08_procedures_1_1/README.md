# Week 08 — Procedures (1)

This folder contains solved SQL tasks for Week 08 based on the educational airbase database.

## Topics

* stored procedures
* `CREATE PROCEDURE`
* procedural SQL
* batch loading
* daily data loading
* local analytical storage
* `PL/pgSQL`
* input parameters
* `GET DIAGNOSTICS`
* load logging
* idempotent reload logic
* creating objects in the `sandbox` schema

## Task Description

The task is to design a local analytical storage structure for a new regional hub and create a procedure that loads historical data from the central database in daily batches.

The central database contains historical information about flights, aircraft and tickets. Since loading all historical data at once may be too heavy, the solution loads data batch by batch for one selected day and one selected hub airport.

## Created Objects

The script creates the following database objects:

* `sandbox.kudravceva_hub_flights` — local flight-level storage for the regional hub
* `sandbox.kudravceva_hub_tickets` — local ticket/passenger/seat-level storage for loaded flights
* `sandbox.kudravceva_hub_load_log` — batch loading log
* `sandbox.kudravceva_p_load_hub_day` — procedure for daily batch loading

## Naming Convention

Objects are created using snake_case according to the course naming convention:

* `p` — procedure

Example:

* `sandbox.kudravceva_p_load_hub_day`

## Files

* `tasks_1_1.sql` — solution for task 1

## Notes

The procedure loads flights for one selected day where the hub airport is either the departure airport or the arrival airport.

The solution uses idempotent reload logic: before inserting a new batch for the same date and hub airport, previously loaded rows for this batch are deleted and then inserted again.

After review and moving the task to `Done`, created database objects should be deleted using the cleanup commands included at the end of the SQL script.
