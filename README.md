# Ballerina

sudo docker run -d --name mysql -e MYSQL_ROOT_PASSWORD=root -v /opt/mysql/data:/var/lib/mysql -p 3305:3306 mysql:latest

docker exec -it mysql /bin/bash
mysql -uroot -proot
