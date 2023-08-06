import ballerina/http;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/sql;
import ballerina/time;

type User record {|
    readonly int id;
    string name;
    @sql:Column {name: "birth_date"}
    time:Date birthDate;
    @sql:Column {name: "mobile_number"}
    string mobileNumber;
|};

type NewUser record {|
    string name;
    @sql:Column {name: "birth_date"}
    time:Date birthDate;
    @sql:Column {name: "mobile_number"}
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
    "social_media_db_new", 3306
);

service /social\-media on new http:Listener(9090) {
    resource function get users() returns User[]|error {
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

    resource function post users(NewUser newUser) returns User|sql:Error|error {
        sql:ExecutionResult|sql:Error insertResult = socialMediaDB->execute(`
        INSERT INTO users (name, birth_date, mobile_number) 
        VALUES (${newUser.name}, ${newUser.birthDate}, ${newUser.mobileNumber});`);

        if insertResult is sql:ExecutionResult {
            User|sql:Error user = socialMediaDB->queryRow(`SELECT * FROM users WHERE id = ${insertResult.lastInsertId}`);
            if user is sql:Error {
                return user;
            }
            return user;
        }
        return insertResult;
    }

    // UPDATE USER BY ID
    resource function put users/[int id](NewUser updatedUser) returns User|UserNotFound|error {
        // Check if the user exists
        User|sql:Error userBeforeUpdate = socialMediaDB->queryRow(`SELECT * FROM users WHERE id = ${id}`);
        if userBeforeUpdate is sql:NoRowsError {
            UserNotFound userNotFound = {
                body: {message: string `id ${id} not found`, details: "User not found", timeStamp: time:utcNow()}
            };
            return userNotFound;
        }

        // Update the user in the database
        sql:ExecutionResult|sql:Error updateResult = socialMediaDB->execute(`
        UPDATE users SET name = ${updatedUser.name}, birth_date = ${updatedUser.birthDate}, mobile_number = ${updatedUser.mobileNumber}
        WHERE id = ${id};`);

        // Check if the update was successful
        if updateResult is sql:ExecutionResult {
            // Return the updated user
            User|sql:Error updatedUserDetails = socialMediaDB->queryRow(`SELECT * FROM users WHERE id = ${id}`);
            if updatedUserDetails is sql:Error {
                return updatedUserDetails;
            }
            return updatedUserDetails;
        }

        return updateResult;
    }

    // DELETE USER BY ID

    resource function delete users/[int id]() returns User|UserNotFound|error {
        // Check if the user exists
        User|sql:Error userBeforeDelete = socialMediaDB->queryRow(`SELECT * FROM users WHERE id = ${id}`);
        if userBeforeDelete is sql:NoRowsError {
            UserNotFound userNotFound = {
                body: {message: string `id ${id} not found`, details: "User not found", timeStamp: time:utcNow()}
            };
            return userNotFound;
        }

        // Delete the user from the database
        sql:ExecutionResult|sql:Error deleteResult = socialMediaDB->execute(`
        DELETE FROM users WHERE id = ${id};`);

        // Check if the delete was successful
        if deleteResult is sql:ExecutionResult {
            // Return the deleted user
            User|sql:Error deletedUserDetails = socialMediaDB->queryRow(`SELECT * FROM users WHERE id = ${id}`);
            if deletedUserDetails is sql:Error {
                return deletedUserDetails;
            }
            return deletedUserDetails;
        }

        return deleteResult;
    }

}

