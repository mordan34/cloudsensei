#!/bin/bash

security find-generic-password -s "n8n_db_password" -w > secrets/db_password.txt
security find-generic-password -s "n8n_auth_password" -w > secrets/n8n_auth_password.txt

# Start all containers
docker-compose up -d
