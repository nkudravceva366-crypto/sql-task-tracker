CREATE TABLE IF NOT EXISTS tasks (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title text NOT NULL,
  category text NOT NULL,
  priority smallint NOT NULL CHECK (priority BETWEEN 1 AND 5),
  is_done boolean NOT NULL DEFAULT false,
  estimate_hours numeric(4,1) NOT NULL DEFAULT 1.0 CHECK (estimate_hours >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  due_date date
);
