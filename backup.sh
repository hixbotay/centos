#!/bin/bash

SERVER_NAME=VINADC_1
TIMESTAMP=$(date +"%F")
BACKUP_DIR="/root/backup/$TIMESTAMP"
MYSQL=/usr/bin/mysql
MYSQLDUMP=/usr/bin/mysqldump
SECONDS=0
DATE_NOW="$(date +'%a')"
echo "Starting Backup Database"
# MySQL settings
mysql_user="root"
mysql_password="T@mth4n1324"
# Check MySQL password
echo exit | mysql --user=${mysql_user} --password=${mysql_password} -B 2>/dev/null
if [ "$?" -gt 0 ]; then
echo "MySQL ${mysql_user} password incorrect"
exit 1
else
echo "MySQL ${mysql_user} password correct."
fi
#backup file
echo "Starting Backup Website"
echo ""


# Loop through home directory
for D in /home/*; do
if [ -d "${D}" ]; then
domain=${D##*/}
echo "- "$domain
#database
if [ -e $D"/backup.txt" ]; then
mkdir -p "$BACKUP_DIR/$domain"
mkdir -p "$BACKUP_DIR/$domain/$TIMESTAMP"
if [ $DATE_NOW = Mon ]; then
zip -r $BACKUP_DIR/$domain/$TIMESTAMP/file.zip /home/$domain/public_html/ -q -x /home/$domain/public_html/wp-content/cache/**\* *.git* \.* *.zip #Exclude cache
else
zip -r $BACKUP_DIR/$domain/$TIMESTAMP/file.zip /home/$domain/public_html/ -q -x /home/$domain/public_html/wp-content/cache/**\* /home/$domain/public_html/wp-content/uploads/**\* *.git* \.* *.zip #Exclude cache
fi
database=$(<${D}"/backup.txt")
#additional_mysqldump_params="--skip-lock-tables"
additional_mysqldump_params=""
echo "Creating backup of \"${database}\" database"
mysqldump ${additional_mysqldump_params} --user=${mysql_user} --password=${mysql_password} ${database} | gzip > "${BACKUP_DIR}/$domain/$TIMESTAMP/database.gz"
chmod 600 "${BACKUP_DIR}/$domain/$TIMESTAMP/database.gz"
fi
fi
done
echo "Finished"
#backup nginx
echo "Starting Backup Nginx Configuration";
mkdir -p "$BACKUP_DIR/nginx/$TIMESTAMP"
zip -r $BACKUP_DIR/nginx/$TIMESTAMP/file.zip /etc/nginx/conf.d/
echo "Finished";
size=$(du -sh $BACKUP_DIR | awk '{ print $1}')

echo "Starting Uploading Backup";
/usr/sbin/rclone move $BACKUP_DIR "remote:$SERVER_NAME" >> /var/log/rclone.log 2>&1

# Clean up
echo "Removing older file";
rm -rf $BACKUP_DIR
/usr/sbin/rclone -q --min-age 2w delete "remote:$SERVER_NAME" #Remove all backups older than 2 week
/usr/sbin/rclone -q --min-age 2w rmdirs "remote:$SERVER_NAME" #Remove all empty folders older than 2 week
echo "Finished";
echo '';

duration=$SECONDS
echo "Total $size, $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
