# Heroku Web bootstrap script
# Updates the Web root to public/

sed -i 's/Listen 80/Listen '$PORT'/' /app/apache/conf/httpd.conf
sed -i 's/^DocumentRoot/# DocumentRoot/' /app/apache/conf/httpd.conf
sed -i 's/^ServerLimit 1/ServerLimit 8/' /app/apache/conf/httpd.conf
sed -i 's/^MaxClients 1/MaxClients 8/' /app/apache/conf/httpd.conf

for var in `env|cut -f1 -d=`; do
  echo "PassEnv $var" >> /app/apache/conf/httpd.conf;
done

# Setup apache logs
touch /app/apache/logs/error_log
touch /app/apache/logs/access_log
tail -F /app/apache/logs/error_log &
tail -F /app/apache/logs/access_log &
export LD_LIBRARY_PATH=/app/php/ext
export PHP_INI_SCAN_DIR=/app/www

# Start a temporary apache process
# This will display the index.php in the root
# while we are booting the ZF2 application
/app/apache/bin/httpd -DNO_DETACH &
PID=$!

echo "Installing application"
sh www/heroku/app-boot.sh

# Add our local configuration to the apache configuration
echo "Include /app/www/heroku/conf/*.conf" >> /app/apache/conf/httpd.conf

# Restart httpd with new configuration
kill $PID
sleep 2

echo "Launching apache"
exec /app/apache/bin/httpd -DNO_DETACH
