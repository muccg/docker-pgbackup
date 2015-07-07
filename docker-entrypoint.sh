#!/bin/bash
# Derived from https://wiki.postgresql.org/wiki/Automated_Backup_on_Linux
##############################
## POSTGRESQL BACKUP CONFIG ##
##############################
 
# Optional system user to run backups as.  If the user the script is running as doesn't match this
# the script terminates.  Leave blank to skip check.
: ${BACKUP_USER:="postgres"}
 
# Optional hostname to adhere to pg_hba policies.  Will default to "localhost" if none specified.
: ${PGHOST:="localhost"}
 
# Optional username to connect to database as.  Will default to "postgres" if none specified.
: ${PGUSER:="postgres"}

# Optional password to connect to database
: ${PGPASSWORD:="postgres"}
 
# This dir will be created if it doesn't exist.  This must be writable by the user the script is
# running as.
BACKUP_DIR=/data/
 
# List of strings to match against in database name, separated by space or comma, for which we only
# wish to keep a backup of the schema, not the data. Any database names which contain any of these
# values will be considered candidates. (e.g. "system_log" will match "dev_system_log_2010-01")
: ${SCHEMA_ONLY_LIST:=""}
 
# Will produce a custom-format backup if set to "yes"
: ${ENABLE_CUSTOM_BACKUPS:="yes"}
 
# Will produce a gzipped plain-format backup if set to "yes"
: ${ENABLE_PLAIN_BACKUPS:="yes"}
 
export PGPASSWORD BACKUP_USER PGHOST PGUSER BACKUP_DIR SCHEMA_ONLY_LIST ENABLE_CUSTOM_BACKUPS ENABLE_PLAIN_BACKUPS
 
#### SETTINGS FOR ROTATED BACKUPS ####
 
# Which day to take the weekly backup from (1-7 = Monday-Sunday)
: ${DAY_OF_WEEK_TO_KEEP:="5"}
 
# Number of days to keep daily backups
: ${DAYS_TO_KEEP:="7"}
 
# How many weeks to keep weekly backups
: ${WEEKS_TO_KEEP:="5"}

export DAY_OF_WEEK_TO_KEEP DAYS_TO_KEEP WEEKS_TO_KEEP

# By default we don't encrypt
: ${ENCRYPT:="no"}

# Set this to your encrypt password
: ${ENCRYPT_PASSWORD:="unset"}
 
######################################

echo "HOME is ${HOME}"
echo "WHOAMI is `whoami`"


function encrypt_backup {
    if [ "x${ENCRYPT}" = 'xyes' ]; then
        echo "[Run] Starting encrypt"

        if [ "x${ENCRYPT_PASSWORD}" = 'xunset' ]; then
            echo "Encrypt password not set" && exit 1
        fi

        find ${BACKUP_DIR} -maxdepth 2 -type f -not \( -name "*.enc" -o -name "*.log" -o -name "lockfile" \) \
            -exec echo '{}' ';' \
            -exec openssl enc -aes-256-cbc -e -in '{}' -out '{}'.enc -pass pass:"${ENCRYPT_PASSWORD}" ';' \
            -exec rm -f '{}' ';'
    fi
}


if [ "$1" = 'backup' ]; then
    echo "[Run] Starting backup"
    date

    (
        flock -n 9 || exit 1
        time /pg_backup_rotated.sh 2>&1 | tee -a /data/backup.log
        encrypt_backup 2>&1 | tee -a /data/backup.log
    ) 9>/data/lockfile

    exit $?
fi

echo "[RUN]: Builtin command not provided [backup]"
echo "[RUN]: $@"

exec "$@"
