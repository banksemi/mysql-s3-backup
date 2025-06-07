FROM alpine:latest

ENV MYSQL_HOST=mysql_host_dummy \
    MYSQL_PORT=3306 \
    MYSQL_USER=backup_user_dummy \
    MYSQL_PASSWORD=backup_password_dummy \
    MYSQL_DATABASE=all_databases \
    S3_BUCKET_NAME=my-mysql-backup-bucket-dummy \
    AWS_REGION=ap-northeast-2


RUN apk add --no-cache \
    mariadb-client \
    rclone \
    dcron \
    bash \
    ca-certificates \
    tini \
    && rm -rf /var/cache/apk/*

WORKDIR /app

COPY backup.sh /app/backup.sh
COPY cron_job /etc/crontabs/root

RUN chmod +x /app/backup.sh && \
    chmod 0600 /etc/crontabs/root

RUN mkdir -p /var/lib/mysql_backup

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["crond", "-f", "-L", "/var/log/cron.log"]