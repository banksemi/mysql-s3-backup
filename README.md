# mysql-s3-backup

[![Docker Image CI](https://github.com/banksemi/mysql-s3-backup/actions/workflows/build.yaml/badge.svg)](https://github.com/banksemi/mysql-s3-backup/actions/workflows/build.yaml)
[![Docker Image GHCR](https://img.shields.io/badge/Docker%20Image-ghcr.io%2Fbanksemi%2Fmysql--s3--backup-blue)](https://github.com/users/banksemi/packages/container/package/mysql-s3-backup)

A lightweight Docker container designed for automated daily backups of MySQL/MariaDB databases, securely uploading them to an Amazon S3 bucket. It leverages `mariadb-client` for efficient database dumps and `rclone` for reliable S3 synchronization.

## Features

*   **Automated Backups**: Configurable cron job for daily or custom backup schedules.
*   **Flexible Database Selection**: Backup all databases or specify individual ones.
*   **Secure S3 Integration**: Utilizes AWS IAM Roles for authentication, ensuring secure access to your S3 bucket without embedding credentials.
*   **Lightweight**: Built on Alpine Linux for a minimal footprint.

## How It Works

This project provides a self-contained Docker image that simplifies your database backup routine:

1.  **Container Setup**: The Docker image includes `mariadb-client` for dumping databases and `rclone` for transferring files to S3, along with `dcron` for scheduling.
2.  **Cron Job**: A cron job inside the container is set up to execute the `backup.sh` script at a predefined interval (default: daily at 2 AM UTC).
3.  **Backup Script (`backup.sh`)**:
    *   Connects to your specified MySQL/MariaDB server.
    *   Performs a `mariadb-dump` of the configured databases (all or specific ones) into a timestamped SQL file.
    *   Uses `rclone move` to securely transfer the generated SQL backup file from the container to your S3 bucket. `rclone` is configured to use AWS IAM roles or environment variables for authentication.
    *   The `move` command ensures that the local backup file is deleted after successful upload to S3, preventing disk space issues.

## Getting Started

### Prerequisites

*   **Docker**: Ensure Docker is installed on your host system.
*   **AWS S3 Bucket**: You need an existing Amazon S3 bucket where your backups will be stored.
*   **AWS Credentials/IAM Role**: The container needs permissions to access your S3 bucket. This is best managed using an [AWS IAM Role](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html) attached to the EC2 instance or Kubernetes Service Account running the container. Alternatively, you can provide `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as environment variables, though an IAM role is preferred for security.

### Docker Image

The Docker image is publicly available on GitHub Container Registry (GHCR):

```
ghcr.io/banksemi/mysql-s3-backup:main
```

### Environment Variables

You **must** configure the following environment variables when running the Docker container:

| Variable         | Description                                                                                                                                              | Required | Default Value (Dummy)             |
| :--------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------- | :------- | :-------------------------------- |
| `MYSQL_HOST`     | The hostname or IP address of your MySQL/MariaDB server.                                                                                                 | Yes      | `mysql_host_dummy`                |
| `MYSQL_PORT`     | The port of your MySQL/MariaDB server.                                                                                                                   | Yes      | `3306`                            |
| `MYSQL_USER`     | The MySQL/MariaDB user with appropriate backup permissions (e.g., `SELECT`, `LOCK TABLES`, `SHOW VIEW`).                                                | Yes      | `backup_user_dummy`               |
| `MYSQL_PASSWORD` | The password for the MySQL/MariaDB user. **Highly recommended to use Docker Secrets or a secrets management solution for this.**                             | Yes      | `backup_password_dummy`           |
| `MYSQL_DATABASE` | The database(s) to backup. Use `all_databases` to backup all available databases. For multiple specific databases, provide a space-separated list (e.g., `"my_db another_db"`). | Yes | `all_databases`                   |
| `S3_BUCKET_NAME` | The name of the S3 bucket where the backup files will be stored.                                                                                         | Yes      | `my-mysql-backup-bucket-dummy`    |
| `AWS_REGION`     | The AWS region where your S3 bucket is located (e.g., `us-east-1`, `ap-northeast-2`).                                                                   | Yes      | `ap-northeast-2`                  |

### Running the Container

To start the backup container, replace the placeholder values with your actual database and S3 details:

```bash
docker run -d \
  --name mysql-s3-backup \
  -e MYSQL_HOST="your_mysql_host" \
  -e MYSQL_PORT="3306" \
  -e MYSQL_USER="your_mysql_user" \
  -e MYSQL_PASSWORD="your_mysql_password" \
  -e MYSQL_DATABASE="all_databases" \
  -e S3_BUCKET_NAME="your_s3_bucket_name" \
  -e AWS_REGION="your_aws_region" \
  ghcr.io/banksemi/mysql-s3-backup:latest
```

**Note on Security**: For production environments, it is strongly advised to use Docker Secrets, Kubernetes Secrets, or a dedicated secrets management solution (like AWS Secrets Manager, HashiCorp Vault) for `MYSQL_PASSWORD` and any AWS access keys, instead of passing them directly as environment variables in the `docker run` command.

## S3 Permissions

The `rclone` utility within the container uses the `--s3-env-auth` flag. This means it will automatically pick up AWS credentials from standard environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`) or, ideally, leverage an [IAM Role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-cli_docker.html) attached to the underlying EC2 instance or Kubernetes Service Account.

The IAM Role or user associated with the container requires the following minimum S3 permissions for the designated bucket:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "arn:aws:s3:::bucket_name"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::bucket_name/*"
        }
    ]
}
```

## Manual Backup


You can also trigger a manual backup run for testing:

```bash
docker exec mysql-s3-backup /app/backup.sh
```


## Contributing & Questions

**Pull requests, issues, and all questions are warmly welcome!**  
If you have suggestions for improvements, bug reports, or just want to ask anything, please feel free to open an issue or submit a merge request (PR).
