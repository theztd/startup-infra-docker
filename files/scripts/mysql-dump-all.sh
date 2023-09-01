#!/bin/bash

# Configure me
LOG_FILE=/var/log/mysql-backup.log
METRICS_PATH=/var/metrics/mysqldump.prom
BACKUP_DIR=/home/backups



#
# Do NOT touch anything bellow this line
#
DATE=$(date +%F-%H%M)


echo "# HELP mysqldump_status Per database dump result 0.. OK, 1.. ERR" > /tmp/metrics.tmp

echo "# HELP mysqldump_size_bytes Database dump size in bytes" >> /tmp/metrics.tmp
echo "# TYPE mysqldump_size_bytes gauge" >> /tmp/metrics.tmp
echo "# HELP mysqldump_duration_sec Database dump duration in seconds" >> /tmp/metrics.tmp
echo "# TYPE mysqldump_duration_sec gauge" >> /tmp/metrics.tmp

for db in `mysql -sNe 'show databases;' | grep -vE '_schema|sys'`; do
	dump_file=${BACKUP_DIR}/$db-${DATE}.sql.gz
	start=`date +%s`

	echo "Backup $db into $dump_file" | tee -a ${LOG_FILE}

	mysqldump --add-drop-table $db | gzip > $dump_file
	echo "mysqldump_status{db_name=\"$db\"} $?" >> /tmp/metrics.tmp

	dump_size_bytes=$(du -b $dump_file | cut -f1)
	echo "mysqldump_size_bytes{db_name=\"$db\"} $dump_size_bytes" >> /tmp/metrics.tmp

	end=`date +%s`
	runtime_sec=$((end-start))

	echo "mysqldump_duration_sec{db_name=\"$db\"} $runtime_sec" >> /tmp/metrics.tmp
done

dump_count=$(ls -l ${BACKUP_DIR} | grep ${DATE} | wc -l)


echo "# HELP mysqldump_count Count backuped databases" >> /tmp/metrics.tmp
echo "# TYPE mysqldump_count gauge" >> /tmp/metrics.tmp
echo "mysqldump_count $dump_count" >> /tmp/metrics.tmp

mv /tmp/metrics.tmp ${METRICS_PATH}
