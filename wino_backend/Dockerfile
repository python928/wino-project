FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /code

COPY requirements.txt /code/
RUN pip install --no-cache-dir --disable-pip-version-check -r requirements.txt

COPY . /code/

CMD ["/usr/bin/python3", "manage.py", "runserver", "0.0.0.0:8000"]
