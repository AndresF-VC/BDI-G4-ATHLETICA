-- ##################################################
-- #        SPORTSDB DATABASE CREATION SCRIPT       #
-- ##################################################

-- 01. Create user
CREATE USER sports_admin WITH PASSWORD 'Sports_DB2025**';

-- 02. Create database (with ENCODING='UTF8', TEMPLATE=template0, OWNER: sports_admin)
CREATE DATABASE sportsdb WITH 
    ENCODING='UTF8' 
    LC_COLLATE='es_CO.UTF-8' 
    LC_CTYPE='es_CO.UTF-8' 
    TEMPLATE=template0 
    OWNER = sports_admin;

-- 03. Grant privileges
GRANT ALL PRIVILEGES ON DATABASE sportsdb TO sports_admin;

-- 04. Create Schema
CREATE SCHEMA IF NOT EXISTS olympus AUTHORIZATION sports_admin;

-- 05. Comment on database
COMMENT ON DATABASE sportsdb IS ''Database for the comprehensive sports management system';

-- 06. Comment on schema
COMMENT ON SCHEMA olympus IS 'Main schema for managing athletes, events, trainings, and performance tracking';