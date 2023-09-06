import ballerina/http;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/sql;
import ballerina/time;

type User record {|
    readonly int id;
    string device_id;
    string connection_id;
    string name;
    string address;
    string email;
    string phone_number;
|};

type NewUser record {|
    string device_id;
    string connection_id;
    string name;
    string address;
    string email;
    string phone_number;
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

service /test on new http:Listener(9090) {

    // Show hello world message
    resource function get hello() returns string {
        return "Hello World!";
    }

    isolated resource function get users() returns User[]|error {
        mysql:Client isolatedSocialMediaDB = check new ("localhost", "root", "", "bal_test", 3306);
        stream<User, sql:Error?> usersStream = isolatedSocialMediaDB->query(`SELECT * FROM users`);
        return from var user in usersStream
            select user;
    }

    isolated resource function get users/[int id]() returns User|UserNotFound|error {
        mysql:Client isolatedSocialMediaDB = check new ("localhost", "root", "", "bal_test", 3306);

        User|sql:Error user = isolatedSocialMediaDB->queryRow(`SELECT * FROM users WHERE id = ${id}`);
        if user is sql:NoRowsError {
            UserNotFound uerNotFound = {
                body: {message: string `id ${id} not found`, details: "User not found", timeStamp: time:utcNow()}
            };
            return uerNotFound;
        }
        return user;
    }

    isolated resource function post users(NewUser newUser) returns User|sql:Error|error {
        mysql:Client isolatedSocialMediaDB = check new ("localhost", "root", "", "bal_test", 3306);
        sql:ExecutionResult|sql:Error insertResult = isolatedSocialMediaDB->execute(`
        INSERT INTO users (device_id, connection_id, name, address, email, phone_number)
        VALUES (${newUser.device_id}, ${newUser.connection_id}, ${newUser.name}, ${newUser.address}, ${newUser.email}, ${newUser.phone_number});
        `);

        if insertResult is sql:ExecutionResult {
            User|sql:Error user = isolatedSocialMediaDB->queryRow(`SELECT * FROM users WHERE id = ${insertResult.lastInsertId}`);
            if user is sql:Error {
                return user;
            }
            return user;
        }
        return insertResult;
    }

    // UPDATE USER BY ID
    isolated resource function put users/[int id](NewUser updatedUser) returns User|UserNotFound|error {
        mysql:Client isolatedSocialMediaDB = check new ("localhost", "root", "", "bal_test", 3306);

        // Check if the user exists
        User|sql:Error userBeforeUpdate = isolatedSocialMediaDB->queryRow(`SELECT * FROM users WHERE id = ${id}`);
        if userBeforeUpdate is sql:NoRowsError {
            UserNotFound userNotFound = {
                body: {message: string `id ${id} not found`, details: "User not found", timeStamp: time:utcNow()}
            };
            return userNotFound;
        }

        // Update the user in the database
        sql:ExecutionResult|sql:Error updateResult = isolatedSocialMediaDB->execute(`
            UPDATE users SET device_id = ${updatedUser.device_id}, connection_id = ${updatedUser.connection_id}, name = ${updatedUser.name}, address = ${updatedUser.address}, email = ${updatedUser.email}, phone_number = ${updatedUser.phone_number}
            WHERE id = ${id};
            `);

        // Check if the update was successful
        if updateResult is sql:ExecutionResult {
            // Return the updated user
            User|sql:Error updatedUserDetails = isolatedSocialMediaDB->queryRow(`SELECT * FROM users WHERE id = ${id}`);
            if updatedUserDetails is sql:Error {
                return updatedUserDetails;
            }
            return updatedUserDetails;
        }
        return updateResult;
    }

    // DELETE USER BY ID

    resource function delete users/[int id]() returns User|UserNotFound|error {
        mysql:Client isolatedSocialMediaDB = check new ("localhost", "root", "", "bal_test", 3306);

        // Check if the user exists
        User|sql:Error userBeforeDelete = isolatedSocialMediaDB->queryRow(`SELECT * FROM users WHERE id = ${id}`);
        if userBeforeDelete is sql:NoRowsError {
            UserNotFound userNotFound = {
                body: {message: string `id ${id} not found`, details: "User not found", timeStamp: time:utcNow()}
            };
            return userNotFound;
        }

        // Delete the user from the database
        sql:ExecutionResult|sql:Error deleteResult = isolatedSocialMediaDB->execute(`
            DELETE FROM users WHERE id = ${id};`);

        // Check if the delete was successful
        if deleteResult is sql:ExecutionResult {
            // Return the deleted user
            User|sql:Error deletedUserDetails = isolatedSocialMediaDB->queryRow(`SELECT * FROM users WHERE id = ${id}`);
            if deletedUserDetails is sql:Error {
                return deletedUserDetails;
            }
            return deletedUserDetails;
        }

        return deleteResult;
    }

}
