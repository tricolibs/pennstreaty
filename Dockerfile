FROM python:3.8

WORKDIR /app
ENV DJANGO_SETTINGS_MODULE=QI.settings_docker

RUN pip install --upgrade pip wheel setuptools requests

COPY requirements.txt /app/requirements.txt
RUN pip install -r /app/requirements.txt

COPY . /app

EXPOSE 8000
ENV PORT=8000

RUN SECRET_KEY=1 python manage.py collectstatic --no-input
CMD gunicorn --reload --bind 0.0.0.0:${PORT:-8000} QI.wsgi:application
