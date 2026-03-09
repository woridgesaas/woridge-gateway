# API Gateway with Kong - Installation

This README describes how to deploy the Kong API Gateway with its PostgreSQL database using Docker Compose.

## Prerequisites

- Docker and Docker Compose installed
- Our external Docker network named `woridge-external-network` 

## Configuration

1. **`.env` file**: create a `.env` file at the root with the following variables:

   ```env
   # PostgreSQL Database
   POSTGRES_USER=kong_user
   POSTGRES_PASSWORD=my_password
   POSTGRES_DB=kong

   # Kong (must use the same password as POSTGRES_PASSWORD)
   KONG_PG_PASSWORD=my_password

## Verifying Operation
1. **Admin GUI** (management web interface): `http://localhost:8002`
2. Command line: `curl localhost:8001` should return OK 200

## Workflow & Collaboration (decK)

Since Kong’s configuration is stored in the database, we use the **decK** tool to version our routes and plugins on Git via the `kong.yaml` file.

### Export your configuration
If you have added a service or a plugin via the Dashboard, you must save your changes into the `kong.yaml` file before doing a `git push`:

```bash
docker-compose run --rm deck dump -o kong.yaml
```

### Import configuration (Sync)
After performing a git pull, update your local Gateway with the team’s changes:
```bash
docker-compose run --rm deck sync -s kong.yaml
```
