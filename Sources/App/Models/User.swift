//
//  User.swift
//  App
//
//  Created by Andrei GHERGHE on 05/05/2018.
//

import FluentMySQL
import Vapor
import Authentication

/// A single entry of a User list.

public enum Authorization: Int, Codable {
    case guest
    case user
    case partner
    case owner
}

final class User: MySQLUUIDModel {
    /// The unique identifier for this `User`.
    var id: UUID?
    
    /// The email for this `User`.
    var email: String?
    
    /// The username for this `User`.
    var username: String
    
    /// The age for this `User`.
    var age: Int?

    /// The bonus points for this `User`.
    var points: Int? = 0
    
    /// The hashed password for this `User`.
    var password: String

    /// The city for this `User`.
    var city: String?

    /// The gender for this `User`.
    var gender: Int?

    /// Auth level for the `User`
//    var authorization: Authorization?

    /// Creates a new `User`.
    init(id: UUID? = nil,
         email: String?,
         username: String,
         age: Int?,
         password: String,
         gender: Int?,
         city: String?
//         authorization: Authorization?
        ) {
        self.id = id
        self.email = email
        self.username = username
        self.age = age
        self.points = 0
        self.password = password
        self.gender = gender
        self.city = city
//        self.authorization = authorization
    }

    func awardPoints() {
        if self.points == nil {
            self.points = 0
        }
        self.points = self.points! + 1
    }
}

struct UserProfileResponse: Content {
    let username: String?
    let email: String?
    let points: Int?
    let gender: Int?
    let city: String?
    let age: Int?
}

struct LoggedUserResponse: Content {
    let username: String
    let token: String
}

/// Allows `User` to be used as a dynamic migration.
extension User: Migration { }

/// Allows `User` to be encoded to and decoded from HTTP messages.
extension User: Content { }

/// Allows `User` to be used as a dynamic parameter in route definitions.
extension User: Parameter { }

extension User {
    var comments: Children<User, PollComment> {
        return children(\.userID)
    }

    //TODO: ADD POLL VOTE CHILDREN
}

extension User: TokenAuthenticatable, BasicAuthenticatable {
    public typealias TokenType = TerraToken
    
    public static var usernameKey : WritableKeyPath<User, String> = \User.username
    public static var passwordKey : WritableKeyPath<User, String> = \User.password
}
