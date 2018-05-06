//
//  BearerToken.swift
//  App
//
//  Created by Andrei GHERGHE on 06/05/2018.
//
// thanks @bensyverson

import FluentSQLite
import Vapor
import Authentication

final class TerraToken: SQLiteModel {
    var id: Int?
    
    var token: String
    var userID: Int
    
    init(id: Int? = nil, token: String, userId: Int) {
        self.id = id
        self.token = token
        self.userID = userId
    }
}

extension TerraToken {
    var user: Parent<TerraToken, User> {
        return parent(\.userID)
    }
}

extension TerraToken: Migration { }
extension TerraToken: Content { }
extension TerraToken: Parameter { }

extension TerraToken: Token {
    static var userIDKey: WritableKeyPath<TerraToken, Int> {
        return \TerraToken.userID
    }
    
    static var tokenKey: WritableKeyPath<TerraToken, String> {
        return \TerraToken.token
    }
    
    typealias UserType = User
}

extension Request {
    func user() throws -> User {
        return try requireAuthenticated(User.self)
    }
}
