-- Rename public schema of Pagila example to demonstrate data staging
ALTER SCHEMA public RENAME TO source;
ALTER DATABASE postgres SET search_path TO source;