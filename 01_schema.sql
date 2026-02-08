CREATE DATABASE palantir_intel;

CREATE TABLE threat_actors (
    actor_id SERIAL PRIMARY KEY,
    actor_name VARCHAR(100) NOT NULL,
    region VARCHAR(50),
    sophistication_tier VARCHAR(20),
    is_state_backed BOOLEAN DEFAULT FALSE
);

CREATE TABLE tools (
    tool_id SERIAL PRIMARY KEY,
    tool_name VARCHAR(100) NOT NULL,
    tool_type VARCHAR(50),
    is_commodity BOOLEAN DEFAULT TRUE
);

CREATE TABLE incidents (
    incident_id SERIAL PRIMARY KEY,
    actor_id INT NOT NULL,
    tool_id INT,
    incident_date DATE NOT NULL,
    severity_score INT CHECK (severity_score BETWEEN 1 AND 10),
    target_sector VARCHAR(50),
    description TEXT,
    FOREIGN KEY (actor_id) REFERENCES threat_actors(actor_id) ON DELETE CASCADE,
    FOREIGN KEY (tool_id) REFERENCES tools(tool_id) ON DELETE SET NULL
);