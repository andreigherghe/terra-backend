//
//  User.swift
//  App
//
//  Created by Andrei GHERGHE on 05/05/2018.
//

import FluentSQLite
import Vapor

/// A single entry of a User list.
final class User: SQLiteModel {
    /// The unique identifier for this `User`.
    var id: Int?
    
    /// The email for this `User`.
    var email: String
    
    /// The username for this `User`.
    var username: String
    
    /// The age for this `User`.
    var age: Int?
    
    /// The phone for this `User`.
    var phone: String?
    
    /// The bonus points for this `User`.
    var points: Int
    
    /// Creates a new `User`.
    init(id: Int? = nil,
         email: String,
         username: String,
         age: Int?,
         phone: String?) {
        self.id = id
        self.email = email
        self.username = username
        self.age = age
        self.phone = phone
        self.points = 0
    }
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
}
