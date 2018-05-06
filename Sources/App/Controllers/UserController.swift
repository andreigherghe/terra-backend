//
//  UserController.swift
//  App
//
//  Created by Andrei GHERGHE on 06/05/2018.
//

import Vapor

/// Controlers basic CRUD operations on `User`s.
final class UserController {    
    /// Saves a decoded `User` to the database.
    func create(_ req: Request) throws -> Future<User> {
        return try req.content.decode(User.self).flatMap { todo in
            return todo.save(on: req)
        }
    }
    
    /// Deletes a parameterized `User`.
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(User.self).flatMap { todo in
            return todo.delete(on: req)
            }.transform(to: .ok)
    }
}
