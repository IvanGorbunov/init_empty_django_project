#!/bin/sh

until cd ./src
do
    echo "Waiting for server volume..."
done

# run a flower
celery --app=settings --broker="${CELERY_BROKER_URL}" --result-backend="${CELERY_RESULT_BACKEND}" flower