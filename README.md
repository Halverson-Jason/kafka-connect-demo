Kafka Connect local stack (MySQL -> Kafka -> PostgreSQL)

Overview

This docker-compose stack brings up:
- MySQL as the source database, pre-seeded with initial data.
- PostgreSQL as the sink database, pre-provisioned with required tables.
- A three-node Apache Kafka cluster (KRaft mode) for messaging.
- Kafka Connect (standalone) running the JDBC Source (MySQL) and JDBC Sink (PostgreSQL) connectors.

Folder layout (important)

- mysql-init: initialization scripts for MySQL. Everything in this folder is run automatically when the MySQL container first starts. This is the seed data for the JDBC Source connector (for example, seed.sql).
- postgres: initialization scripts for PostgreSQL. These create the tables expected by the JDBC Sink connector (for example, postgresql-create-table.sql).
- kafka-connect: holds connector plugins and JDBC drivers. In particular, kafka-connect/plugins is mounted into the Kafka Connect container and must contain the Kafka Connect JDBC plugin and the database JDBC drivers.
  - Example layout:
    - kafka-connect/plugins/confluentinc-kafka-connect-jdbc-<version>/
    - kafka-connect/plugins/mysql-connector-j-<version>.jar (if not already included by the plugin)
    - kafka-connect/plugins/postgresql-<version>.jar (if not already included by the plugin)

Services in docker-compose.yml

1) mysql
- Image: mysql:latest
- Ports: 3306 -> 3306
- Credentials: root password jason; default database kafka_app
- Volumes:
  - ./mysql-init:/docker-entrypoint-initdb.d:ro — runs SQL files on first start to seed data.

2) postgres
- Image: postgres:latest
- Ports: 5432 -> 5432
- Credentials: POSTGRES_PASSWORD=jason; default database users
- Volumes:
  - ./postgres/postgresql-create-table.sql:/docker-entrypoint-initdb.d/1-create-table.sql — creates tables used by the sink connector.

3) kafka-1, kafka-2, kafka-3
- Image: confluentinc/cp-kafka:latest (KRaft mode)
- Exposed ports:
  - kafka-1: 9092 (external)
  - kafka-2: 9094 (external)
  - kafka-3: 9096 (external)
- Each node stores data under docker/kafka-volumes/kafka-*/data on your host.

4) kafka-connect
- Image: confluentinc/cp-kafka-connect:latest
- Port: 8083 -> 8083 (Kafka Connect REST API)
- Mounts folders and files using .env variables (see below).
- Startup command sets CLASSPATH to the JDBC plugin directory and starts connect-standalone with two connector configs (MySQL source and PostgreSQL sink).

Required .env file

docker-compose.yml references several environment variable-based paths. Create docker/.env with entries like the following (paths can be absolute, or relative to the docker folder if you run docker compose from there):
```
HOSTNAME=localhost
CONNECTOR_PLUGINS_PATH=./kafka-connect/plugins
STANDALONE_CONFIG_PATH=./connect-standalone-for-docker-compose.properties
JDBC_MYSQL_SOURCE_CONNECTOR_CONFIG_PATH=./mysql-jdbc-connector-for-docker.properties
JDBC_POSTGRESQL_SINK_CONNECTOR_CONFIG_PATH=./postgresql-jdbc-sink-connector-for-docker.properties
```
Notes
- CONNECTOR_PLUGINS_PATH is mounted to /usr/share/confluent-hub-components inside the Kafka Connect container. This is where the Kafka JDBC connector and drivers must exist.
- STANDALONE_CONFIG_PATH points to the connect worker properties file used by connect-standalone.
- JDBC_MYSQL_SOURCE_CONNECTOR_CONFIG_PATH points to the MySQL JDBC Source connector properties file.
- JDBC_POSTGRESQL_SINK_CONNECTOR_CONFIG_PATH points to the PostgreSQL JDBC Sink connector properties file.
- Example files for these configs are present in this docker folder:
  - connect-standalone-for-docker-compose.properties
  - mysql-jdbc-connector-for-docker.properties
  - postgresql-jdbc-sink-connector-for-docker.properties

How to run

1) From the docker folder, ensure your .env is created and the plugins folder is populated as described above.
2) Start the stack:
   - docker compose up -d
3) Check container health and logs as needed:
   - docker ps
   - docker logs -f kafka-connect-standalone
4) Verify Kafka Connect is up:
   - curl http://localhost:8083/connectors
   You should see an empty list [] initially, then entries once the connectors from the provided property files have started.

Connector flows (at a glance)

- MySQL Source Connector reads from the seeded MySQL database kafka_app (populated via mysql-init) and writes records to Kafka topics.
- PostgreSQL Sink Connector reads those topics and writes to the tables created by postgres/postgresql-create-table.sql.

Credentials and connection defaults (from docker-compose)

- MySQL
  - Host: localhost
  - Port: 3306
  - User: root
  - Password: jason
  - Database: users

- PostgreSQL
  - Host: localhost
  - Port: 5432
  - User: postgres (default)
  - Password: jason
  - Database: users

Troubleshooting

- Plugin not found / Class not found errors:
  - Ensure CONNECTOR_PLUGINS_PATH points to kafka-connect/plugins and that the confluentinc-kafka-connect-jdbc plugin directory exists under it.
  - Confirm the CLASSPATH used in docker-compose points to the correct JDBC plugin version. The compose file currently uses confluentinc-kafka-connect-jdbc-10.9.1/lib/*.

- Path mount errors:
  - Use absolute paths if running docker compose from a different directory than docker.
  - On Windows, prefer full absolute paths; environment variables like ${PWD} may not be available in all shells.

- Port conflicts:
  - Ensure ports 3306 (MySQL), 5432 (PostgreSQL), 8083 (Connect), and 9092/9094/9096 (Kafka) are free.

Teardown

- Stop and remove containers, networks, and volumes created by this compose file:
  - docker compose down

Where things live

- kafka-connect folder: JDBC connector plugin(s) and drivers (mounted to /usr/share/confluent-hub-components inside the container).
- mysql-init folder: seed SQL files executed automatically on first MySQL startup.
- postgres folder: SQL files to create tables for the sink side; postgresql-create-table.sql is mounted on init.