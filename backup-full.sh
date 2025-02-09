#!/bin/bash

# Defining variables
DATE=$(date +"%Y.%m.%d")                                            # The date format used

BACKUP_DIR='/var/backups'                                           # The directory where the archive is created
ARCHIVE_NAME="backup[${DATE}].tar.gz.gpg"                           # The archive name format will be encrypted and have the extension .gpg

LOG_FILE='/var/log/backup-full.log'                                 # Log file

# List on a separate line what needs to be added to the archive. The entire directory or just the file
SOURCE_ITEMS=(
    "/etc/apache2"
    "/etc/mysql"
    "/etc/php/8.3"
    "/var/www/site"
)

ENCRYPTION_PASSWORD='encrypt_password'                              # Password for the archive

MYSQL_USER_DB='mysql_user'                                          # MySQL user
MYSQL_PASSWORD_DB='mysql_password'                                  # MySQL password
MYSQL_DATABASE_DB='mysql_db'                                        # DB name
MYSQL_DUMP_FILE_DB="${BACKUP_DIR}/${MYSQL_USER_DB}_${DATE}.sql"     # Temporary file for the dump

# SFTP settings
SFTP_USER='sftp_user'                                               # SFTP username
SFTP_HOST='127.0.0.1'                                               # SFTP server address
SFTP_PORT='22'                                                      # SFTP port (default is 22)
SFTP_REMOTE_DIR="."                                                 # Directory on the remote server
#SFTP_KEY='/path/to/ssh/key'                                        # Path to the SSH key (if used)
SFTP_PASSWORD='sftp_password'                                       # Variable for storing the password

# Function for writing logs
function log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') > $1" >> "$LOG_FILE"
}

# We record the start time of the script
log_message "Start backup..."

# We check if the backup directory exists; if it doesn't, we create it
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    log_message "Backup directory create: $BACKUP_DIR"
fi

# We log the start of the database dump creation
log_message "Create a dump of the MySQL database: $MYSQL_DATABASE_DB ..."

# We create a dump of the MySQL database
mysqldump -u"$MYSQL_USER_DB" -p"$MYSQL_PASSWORD_DB" "$MYSQL_DATABASE_DB" > "$MYSQL_DUMP_FILE_DB" 2>/dev/null

# We check if the dump was successfully created
if [ $? -ne 0 ]; then
    log_message "Error creating the MySQL database dump: $MYSQL_DATABASE_DB"
    exit 1
else
    log_message "The database dump was successfully created: $MYSQL_DATABASE_DB"
fi

# We add the dump to the list of files for archiving
SOURCE_ITEMS+=("$MYSQL_DUMP_FILE_DB")

# We create a temporary unencrypted archive
TEMP_ARCHIVE="${BACKUP_DIR}/temp_${DATE}.tar.gz"
tar -czf "$TEMP_ARCHIVE" "${SOURCE_ITEMS[@]}" 2>/dev/null

# We check if the temporary archive was successfully created
if [ $? -ne 0 ]; then
    log_message "Error creating temporary archive!"

    # We delete the temporary dump
    rm -f "$MYSQL_DUMP_FILE_DB"
    exit 1
fi

# We encrypt the archive using GPG
echo "$ENCRYPTION_PASSWORD" | gpg --batch --yes --passphrase-fd 0 --symmetric --output "${BACKUP_DIR}/${ARCHIVE_NAME}" "$TEMP_ARCHIVE" 2>/dev/null

# We check if the encryption was successful
if [ $? -eq 0 ]; then
    log_message "The archive has been successfully created and encrypted: ${BACKUP_DIR}/${ARCHIVE_NAME}"

    # We delete the temporary unencrypted archive
    rm -f "$TEMP_ARCHIVE"
    rm -f "$MYSQL_DUMP_FILE_DB"
else
    log_message "Error encrypting the archive!"
    send_telegram "Error encrypting the archive!"
    exit 1
fi

# Uploading the archive via SFTP
log_message "Upload backup start..."

# Using an SSH key for authentication
##sftp -i "$SFTP_KEY" -P "$SFTP_PORT" "$SFTP_USER@$SFTP_HOST" <<EOF >> "$LOG_FILE" 2>&1
##    put "${BACKUP_DIR}/${ARCHIVE_NAME}" "${SFTP_REMOTE_DIR}/${ARCHIVE_NAME}"
##    bye
##EOF

# Using a password for authentication (via sshpass)
sshpass -p "$SFTP_PASSWORD" sftp -P "$SFTP_PORT" "$SFTP_USER@$SFTP_HOST" <<EOF >> "$LOG_FILE" 2>&1
    put "${BACKUP_DIR}/${ARCHIVE_NAME}" "${SFTP_REMOTE_DIR}/${ARCHIVE_NAME}"
    bye
EOF

# Checking the success of the upload
if [ $? -eq 0 ]; then
    log_message "The backup file has been successfully uploaded!"

    # Deleting the local copy
    rm -f "$BACKUP_DIR/$ARCHIVE_NAME"
else
    log_message "Backup upload error!"
    exit 1
fi
