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
import Crypto

final class TerraToken: SQLiteModel {
    var id: Int?
    
    var string: String
    var userID: Int
    
    init(id: Int? = nil, string: String, user: User) throws {
        self.id = id
        self.string = string
        guard let loggedUserId = user.id else {
            throw Abort.init(.badRequest)
        }
        self.userID = loggedUserId
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
        return \TerraToken.string
    }
    
    typealias UserType = User
}

extension Request {
    func user() throws -> User {
        return try requireAuthenticated(User.self)
    }
}

extension TerraToken {
    /// Generates a new token for the supplied User.
    static func generate(for user: User) throws -> TerraToken {
        let aToken = try TerraToken.randomToken()
        return try TerraToken(string: aToken, user: user)
    }
    
    static func randomToken() throws -> String {
        // generate 128 random bits using OpenSSL
        let random = try CryptoRandom().generateData(count: 32)
        // create and return the new token
        return random.base64URLEncodedString()
    }
}

