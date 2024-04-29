#!/bin/sh

apt install gettext -y

# Для БД на хосте
#netstat -nr | grep '^0\.0\.0\.0' | awk '{print $2" host.docker.internal"}' >> /etc/hosts

# На случай если БД бдует долго запускаться
#while ! curl postgres:5432/ 2>&1 | grep '52'; do sleep 1; done

cd ./src

# Миграции и статика
python3 manage.py makemigrations
python3 manage.py migrate --noinput
python3 manage.py collectstatic --no-input --clear
django-admin makemessages --all --ignore=venv
django-admin compilemessages --ignore=venv

# User credentials
email=admin@example.com
password=admin123
echo "from apps.users.models import User; (User.objects.create_superuser(email='$email', password='$password', role='super_admin', is_active=True)) if not User.objects.filter(role='super_admin').exists() else False" | python3 manage.py shell

# Запуск воркеров по очередям
celery -A settings multi start --beat w.no_queue w.low w.high w.flow --loglevel=info --logfile=../logs/%n.log --pidfile=../pids/%n.pid -Q:w.high high -Q:w.low low -Q:w.flow flow



# Запуск самого проекта
#gunicorn clients_portal.wsgi:application --chdir /clients_portal/src/ --bind 0.0.0.0:8000 --workers 2 --timeout 900 --error-logfile ../logs/gunicorn_web_error.log
python3 manage.py runserver 0.0.0.0:8000

exec "$@"