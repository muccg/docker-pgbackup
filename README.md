Postgresql backup based on https://wiki.postgresql.org/wiki/Automated_Backup_on_Linux

docker run -it -v /data/pgbackup:/data --link postgresql:postgresql -e PGUSER=someuser -e PGPASSWORD=somepass -e PGHOST=postgresql pgbackup backup
