-- 1) All unfinished tasks, highest priority first
SELECT *
FROM tasks
WHERE is_done = false
ORDER BY priority DESC, created_at ASC;


-- 2) Tasks with due date in the next 7 days (including today)
SELECT *
FROM tasks
WHERE due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
ORDER BY due_date ASC;


-- 3) Overdue unfinished tasks
SELECT *
FROM tasks
WHERE is_done = false
  AND due_date < CURRENT_DATE
ORDER BY due_date ASC;


-- 4) Number of tasks in each category
SELECT category, COUNT(*) AS task_count
FROM tasks
GROUP BY category
ORDER BY task_count DESC, category ASC;


-- 5) Average estimate_hours by category (only unfinished tasks)
SELECT category, ROUND(AVG(estimate_hours), 2) AS avg_estimate_hours
FROM tasks
WHERE is_done = false
GROUP BY category
ORDER BY avg_estimate_hours DESC, category ASC;
