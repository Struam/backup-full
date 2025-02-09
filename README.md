# Script for automatic backup

## Description

This script is designed to create backups of important data on a local server and send them to a remote server via **SFTP**. It performs the following tasks:
- Database dump creation **MySQL**.
- Archiving of specified directories and files.
- Encrypting the archive using **GPG**.
- Transferring the encrypted archive to a remote server via **SFTP**.
- Logging all actions.

---

## Requirements

For the script to work properly, the following programs need to be installed:

- **mysqldump**: For creating a MySQL database dump.
- **tar**: For creating an archive.
- **gpg**: For encrypting the archive.
- **sshpass**: For passing the password during SFTP connection.
- **sftp**: For uploading the file to a remote server.

### Installing dependencies

On Ubuntu/Debian:

```bash
sudo apt update
sudo apt install mysql-client tar gpg sshpass openssh-client
```

On CentOS/RHEL:
```bash
sudo yum install mysql tar gpg sshpass openssh-clients
```

---

## Script configuration

1.  **Create a script file**:\
Save the script code to a file, for example, **backup.sh**.

2. **Configure the variables**:\
Edit the following variables according to your requirements:
    - **BACKUP_DIR**: Directory for temporary backup storage.
    - **SOURCE_ITEMS**: List of directories and files to include in the archive.
    - **ENCRYPTION_PASSWORD**: Password for encrypting the archive.
    - **MYSQL_USER_DB**, **MYSQL_PASSWORD_DB**, **MYSQL_DATABASE_DB**: Credentials for MySQL access.
    - **SFTP_USER**, **SFTP_HOST**, **SFTP_PORT**, **SFTP_REMOTE_DIR**, **SFTP_PASSWORD**: Connection parameters for the remote server via **SFTP**.

3. **Set access permissions**:\
Make sure only the owner can read and execute the script:

    ```bash
    chmod 700 backup.sh
    ```

4. **Check write permissions**:\
Make sure the script has write permissions for **$BACKUP_DIR** and **$LOG_FILE**.

---

## Usage instructions

1. **Running the script manually**:\
Run the script from the command line:

    ```bash
    ./backup.sh
    ```

2. **Viewing logs**:\
All script actions are recorded in the log file (**$LOG_FILE**). You can view it as follows::

    ```bash
    tail -f /var/log/backup-full.log
    ```

---

## Example configuration

Example settings for backup:

```bash
DATE=$(date +"%Y.%m.%d")
BACKUP_DIR='/var/backups'
ARCHIVE_NAME="backup[${DATE}].tar.gz.gpg"
LOG_FILE='/var/log/backup-full.log'

SOURCE_ITEMS=(
    "/etc/apache2"
    "/etc/mysql"
    "/etc/php/8.3"
    "/var/www/site"
)

ENCRYPTION_PASSWORD='your_encryption_password'
MYSQL_USER_DB='mysql_user'
MYSQL_PASSWORD_DB='mysql_password'
MYSQL_DATABASE_DB='mysql_db'

SFTP_USER='sftp_user'
SFTP_HOST='192.168.1.100'
SFTP_PORT='22'
SFTP_REMOTE_DIR="/backups"
SFTP_PASSWORD='sftp_password'
```
---

## Adding the script to cron

To have the script run automatically on a schedule, add it to **crontab**.

1. Open crontab:

    ```bash
    crontab -e
    ```

2. Add a line to run the script, for example, every day at 03:00:

    ```bash
    0 3 * * * /path/to/backup.sh >> /var/log/backup-cron.log 2>&1
    ```

    Explanation:
    - 0 3 * * *: Runs every day at 03:00.
    - /path/to/backup.sh: Path to the script.
    - \>> /var/log/backup-cron.log 2>&1: Redirecting output to a log file.

3. Save the changes.

---

## Usage examples

1. **Manual execution**:
    ```bash
    ./backup.sh
    ```

2. **Checking logs**:
    ```bash
    cat /var/log/backup-full.log
    ```

3. **Adding to cron for daily execution**:
    ```bash
    crontab -e
    ```

    Add the line:

    ```bash
    0 3 * * * /path/to/backup.sh >> /var/log/backup-cron.log 2>&1
    ```

4. **Checking cron status**:
    ```bash
    crontab -l
    ```

---

## Important notes

- **Security**: Do not store passwords directly in the script. Consider using files with restricted access permissions or environment variables instead.
- **Access permissions**: Make sure the script has the necessary write permissions for **$BACKUP_DIR** and **$LOG_FILE**.
- **Testing**: Before adding the script to cron, test it manually to ensure everything works correctly.

---

## Support

If any questions or issues arise, contact the system administrator or refer to the documentation for the programs used in the script..
