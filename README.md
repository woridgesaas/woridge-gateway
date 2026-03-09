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