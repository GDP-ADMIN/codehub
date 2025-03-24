# This file is used by `docker build`

# https://hub.docker.com/_/python/tags?name=3.12
FROM python:3.12-bookworm

COPY requirements.txt .

RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5001

CMD ["python3", "app.py"]
