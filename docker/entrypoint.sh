#!/bin/bash
set -e

if [[ "$MYSQL_HOST" == "db_server" ]]; then
    echo "Waiting for database..."
    while ! nc -z "$MYSQL_HOST" "$MYSQL_PORT"; do
      sleep 0.1
    done
    echo "Database started"
fi

gunicorn -b 0.0.0.0 app:app

exec "$@"
