#!/bin/bash

# Install empty default Django poject

set -o errexit

# Delete old repo
echo 'Clean folder...'
rm -rf ./.git
rm ./README.md

# Install the Git
echo 'Install the Git...'
git init
git lfs install

# Init settings
echo 'Init settings...'
project_name=""
project_description=""
project_author="IvanGorbunov <falseprogrammerfirst@gmail.com>"
project_version="0.1.0"
#project_license=$5
project_readme="README.md"

deploy=false

# Chekking flags
while [ -n "$1" ] 
do
  case "$1" in
    -g) deploy=true;;
    -n) project_name="$2" 
    shift ;;
    --) shift 
    break ;;
    *) echo "$1 is not an option";;
  esac
  shift
done

# Chekking value "--proj-name"
if [ -z "$project_name" ]; then
  echo "Erorr: not set name of the project (--proj-name)"
  exit 1
fi

if [ "$project_name" = "-g" ]; then
  echo "Erorr: not set name of the project (-n)"
  exit 1
fi

# Copy system files
echo 'Copy system files...'
cp ./src-templats/.gitignore ./
cp ./src-templats/.dockerignore ./
cp -r ./src-templats/docker ./
cp -r ./src-templats/.github ./

# Install Python .venv
echo 'Install Python...'
python3.12 -m venv venv --upgrade-deps
. ./venv/bin/activate



# Install Poetry
echo 'Install Poetry...'
cat << EOF > pyproject.toml
[tool.poetry]
name = "$project_name"
version = "$project_version"
description = "$project_description"
authors = ["$project_author"]
license = "$project_license"
readme = "README.md"

[tool.poetry.dependencies]
python = "^3.12"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
EOF

pip install poetry
poetry self update
# poetry init

# Install Django
echo 'Install Django...'
poetry add Django \
    psycopg2-binary \
    environ django-environ \
    drf-yasg django-debug-toolbar \
    redis celery flower django-redis django-celery-beat django-celery-results \
    coverage django-coverage-plugin \
    django-admin-extra-buttons django-admin-rangefilter \
    django-constrainedfilefield django-timezone-field\
    django-cors-headers \
    django-crispy-forms \
    django-filter django-daterangefilter \
    django-otp \
    django-storages \
    factory-boy django-test-plus \
    django-treebeard \
    djangorestframework djangorestframework-simplejwt drf-writable-nested \
    flake8 \
    black \
    openpyxl \
    Pillow \
    requests

# poetry add django-bootstrap5
# poetry add selenium

# #pip freeze > requirements.txt



# # Install project dependencies
# #pip install '.[dev]'

# Install pre-commit hooks
echo 'Install pre-commit hooks...'
pre-commit install
poetry add pre-commit
cp -r ./src-templats/.pre-commit ./.pre-commit

# Docker hooks
# pre-commit install -c ./.pre-commit/docker.pre-commit-config.yaml

# Local hooks
pre-commit install -c ./.pre-commit/.pre-commit-config.yaml


# Customize the project
echo 'Create django project...'
django-admin startproject $project_name

echo 'Customize the project:'
echo '  - customizing structure of the project'
mv -n ./$project_name ./src
mv -n ./src/$project_name ./src/settings
mkdir -p ./src/apps
mkdir -p ./src/utils

echo '  - customizing settings files'
mkdir -p ./src/settings/settings
mv ./src/settings/settings.py ./src/settings/settings/base_settings.py
echo 'from .base_settings import *' >> ./src/settings/settings/local_settings.py
echo 'from .base_settings import *' >> ./src/settings/settings/prod_settings.py

echo '  - adding .env-files'
cat << EOF > ./src/settings/settings/.env
DEBUG=True
SQL_DEBUG=True
DJANGO_LOG_LEVEL=INFO
SECRET_KEY=
DJANGO_ALLOWED_HOSTS=*

DATABASE_URL=psql://postgres:postgres@127.0.0.1:5436/$project_name
DATABASE_URL_IN_DOCKER=psql://postgres:postgres@db:5432/$project_name
#SQL_ENGINE=django.db.backends.postgresql
#SQL_DATABASE=$project_name
#SQL_USER=postgres
#SQL_PASSWORD=postgres
#SQL_HOST=db
#SQL_PORT=5432

RUN_IN_DOCKER=True

BROKER_URL=redis://localhost:6385/0

REDIS_HOST=redis
REDIS_HOST_LOCAL=localhost
REDIS_PORT=6379
REDIS_PORT_LOCAL=6385

CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0
CELERY_ACCEPT_CONTENT=application/json
CELERY_TASK_SERIALIZER=json
CELERY_RESULT_SERIALIZER=json
CELERY_TIMEZONE=Europe/Moscow


EMAIL_USE_TLS=True
# EMAIL_USE_SSL=False
EMAIL_HOST=smtp.gmail.com
# EMAIL_HOST=smtp.mail.ru
EMAIL_HOST_USER=
# EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=
# EMAIL_HOST_PASSWORD=
EMAIL_PORT=587
EMAIL_ADR_REGISTRATION=
# EMAIL_ADR_REGISTRATION=

STATIC_ROOT=var/www/staticfiles

SENTRY_DSN=
EOF

cp ./src/settings/settings/.env ./src/settings/settings/.env.template

echo '  - customizing base_settings.py:'
echo '    -  1' 
sed -i 's/from pathlib import Path/import environ \
import os \
 \
from datetime import timedelta \
 \
from django.utils.crypto import get_random_string \
from django.utils.translation import gettext_lazy as _ \
from pathlib import Path \
 \
env = environ.Env( \
    # set casting, default value \
    DEBUG=(bool, False) \
) \
environ.Env.read_env() \
 \
 \
def get_secret_key(): \
    if not env.str("SECRET_KEY"): \
        print("[agents_portal] No setting found for SECRET_KEY. Generating a random key...") \
        return get_random_string(length=50) \
    return env.str("SECRET_KEY") \
/g' ./src/settings/settings/base_settings.py

echo '    -  2'
sed -i 's/SECRET_KEY = /SECRET_KEY = get_secret_key()   #/g' ./src/settings/settings/base_settings.py

echo '    -  3'
sed -i 's/BASE_DIR = Path(__file__).resolve().parent.parent/BASE_DIR = Path(__file__).resolve().parent.parent.parent \
ROOT_DIR = environ.Path(__file__) - 3 \
/g' ./src/settings/settings/base_settings.py

echo '    -  4'
sed -i 's/DEBUG = True/DEBUG = env.bool("DEBUG", False)/g' ./src/settings/settings/base_settings.py

echo '    -  5'
sed -i 's/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = env.list("DJANGO_ALLOWED_HOSTS")/g' ./src/settings/settings/base_settings.py

echo '    -  6'
sed -i 's/ROOT_URLCONF = "'$project_name'.urls"/ROOT_URLCONF = "settings.urls"/g' ./src/settings/settings/base_settings.py

echo '    -  7'
sed -i 's/WSGI_APPLICATION = "'$project_name'.wsgi.application"/WSGI_APPLICATION = "settings.wsgi.application"/g' ./src/settings/settings/base_settings.py

echo '  - customizing project`s files:'

echo '    - manage.py'
sed -i 's/'$project_name'.settings/settings.settings.prod_settings/g' ./src/manage.py

echo '    - asgi.py'
sed -i 's/'$project_name'.settings/settings.settings.prod_settings/g' ./src/settings/asgi.py

echo '    - wsgi.py'
sed -i 's/'$project_name'.settings/settings.settings.prod_settings/g' ./src/settings/wsgi.py

# Install Gunicorn
if [ "$deploy" = true ]; then
  echo "Install Gunicorn..."
  ./deploy/install.sh
fi

echo 'Cleaning...'
rm -rf ./src-templats

echo 'Creation finished successfully!'
echo 'rm -rf ./install_django_empty.sh'
