-- This script is executed automatically on first container initialization
-- because it is mounted to /docker-entrypoint-initdb.d

-- Ensure a database exists and use it
CREATE DATABASE IF NOT EXISTS users;
USE users;

-- Create table
CREATE TABLE IF NOT EXISTS user_profiles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Seed data
INSERT INTO user_profiles (first_name, last_name)
VALUES ('Jason', 'halverson');
