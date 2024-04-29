#!/bin/sh

until cd ./src
do
    echo "Waiting for server volume..."
done

# run a worker
# -A app - searches for celery.py within the directory app
celery --app=settings --broker="${CELERY_BROKER_URL}" --result-backend="${CELERY_RESULT_BACKEND}" worker -B --loglevel=info --scheduler django_celery_beat.schedulers:DatabaseScheduler
# --logfile=../logs/celery.log

# run the workers by queries
#celery --app=settings multi start worker --beat w.no_queue w.low w.high w.flow --loglevel=info --logfile=../logs/%n.log --pidfile=../pids/%n.pid -Q:w.high high -Q:w.low low -Q:w.flow flow
