-- Runs once, only when the `db` volume is first created (Postgres only
-- executes docker-entrypoint-initdb.d on an empty data directory). Gives
-- ServerTests its own database, isolated from the one `make serve` /
-- `make migrate` use for local dev, so running tests never touches or
-- wipes data you're poking at manually in the simulator.
CREATE DATABASE mauit_test;
