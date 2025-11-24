CREATE TABLE user_profiles (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
