# This file is used by `docker build`

# https://hub.docker.com/_/python/tags?name=3.10
FROM python:3.10-bullseye

COPY requirements.txt .

RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python3", "app.py"]
