# Ballerina

sudo docker run -d --name mysql -e MYSQL_ROOT_PASSWORD=root -v /opt/mysql/data:/var/lib/mysql -p 3305:3306 mysql:latest

docker exec -it mysql /bin/bash
mysql -uroot -proot

DROP DATABASE IF EXISTS bal_test;
-- Create the database
CREATE DATABASE bal_test;

-- Use the newly created database
USE bal_test;

-- Create the users table
CREATE TABLE users (
id INT AUTO_INCREMENT PRIMARY KEY,
device_id VARCHAR(255),
connection_id VARCHAR(255),
name VARCHAR(255),
address VARCHAR(255),
email VARCHAR(255),
phone_number VARCHAR(15)
);

-- Insert users into the user table
INSERT INTO users (device_id, connection_id, name, address, email, phone_number)
VALUES
('device123', 'connection456', 'John Doe', '123 Main St', 'johndoe@example.com', '555-123-4567'),
('device124', 'connection457', 'Jane Smith', '456 Elm St', 'janesmith@example.com', '555-987-6543');

-- mysql -h ballerina.ckrzcvf9wxc5.ap-northeast-1.rds.amazonaws.com -P 3306 -u admin -p asdfg123
