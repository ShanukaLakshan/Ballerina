import ballerina/http;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/sql;
import ballerina/time;

type User record {|
    readonly int id;
    string name;
    @sql:Column {name: "birth_date"}
    string birthDate;
    @sql:Column {name: "mobile_number"}
    string mobileNumber;
|};

type NewUser record {|
    string name;
    string birthDate;
    string mobileNumber;
|};

type ErrorDetails record {
    string message;
    string details;
    time:Utc timeStamp;
};

type UserNotFound record {|
    *http:NotFound;
    ErrorDetails body;
|};

mysql:Client socialMediaDB = check new ("localhost", "root", "root",
    "social_media_db", 3306
);

service /social\-media on new http:Listener(9090) {
    resource function get getUsers() returns User[]|error {
        stream<User, sql:Error?> usersStream = socialMediaDB->query(`SELECT * FROM users`);
        return from var user in usersStream
            select user;

    }

    resource function get users/[int id]() returns User|UserNotFound|error {
        User|sql:Error user = socialMediaDB->queryRow(`SELECT * FROM users WHERE id = ${id}`);
        if user is sql:NoRowsError {
            UserNotFound uerNotFound = {
                body: {message: string `id ${id} not found`, details: "User not found", timeStamp: time:utcNow()}
            };
            return uerNotFound;
        }
        return user;
    }

    resource function post users(NewUser newUser) returns http:Created|error {
        _ = check socialMediaDB->execute(`
        INSERT INTO users (name, birth_date, mobile_number) 
            VALUES (${newUser.name}, ${newUser.birthDate}, ${newUser.mobileNumber});`);

        return http:CREATED;
    }

}

