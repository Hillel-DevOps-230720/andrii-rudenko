FROM ubuntu:20.04

WORKDIR /app

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -qy \
        netcat-traditional \
        git \
        python3-pip \
        build-essential \
        default-libmysqlclient-dev \
        pkg-config && \
    apt-get -y clean
RUN rm -rf /var/lib/apt/lists /var/cache/apt/archives && \
    git clone https://github.com/saaverdo/flask-alb-app /app && \
    pip install --upgrade pip && \
    pip install -r requirements.txt

EXPOSE 8000

ENV MYSQL_HOST "db_server"
ENV MYSQL_PORT "3306"
ENV MYSQL_USER "flask"
ENV MYSQL_PASSWORD "flask"
ENV MYSQL_DB "flask"
ENV SECRET_KEY "2l0oX4nJB2NJAYal4j4xreacvKJf"

COPY ./entrypoint.sh .
ENTRYPOINT ["./entrypoint.sh"]
