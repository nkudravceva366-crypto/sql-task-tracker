# Week 07 — Query Optimization (1–2)

This folder contains solved SQL tasks for Week 07 based on the educational airbase database.

## Topics

* query optimization
* query documentation
* `EXPLAIN`
* `EXPLAIN ANALYZE`
* execution plan analysis
* indexes
* joins optimization
* filtering strategies
* storage optimization proposals
* materialized views as an optimization idea
* pre-aggregated analytical data

## Files

* `tasks_1_2.sql` — solutions for tasks 1–2

## Notes

The tasks focus on analyzing and documenting a long analytical query, describing possible execution plan nodes, and proposing optimization ideas without necessarily implementing all changes in the database.

Potential optimization directions include:

* replacing repeated scalar subqueries with pre-aggregated CTEs;
* checking indexes for frequent joins and filters;
* analyzing execution plans with `EXPLAIN (ANALYZE, BUFFERS)`;
* considering partitioning for large historical tables;
* using materialized views or summary tables for frequently executed analytical reports.
