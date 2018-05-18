//
//  PollAnswer.swift
//  App
//
//  Created by Andrei GHERGHE on 05/05/2018.
//

import FluentMySQL
import Vapor

/// A single entry of a PollAnswer list.
final class PollAnswer: MySQLModel {
    /// The unique identifier for this `PollAnswer`.
    var id: Int?
    
    /// The unique identifier for the parent `Poll`
    var pollID: Poll.ID?
    
    /// A title describing what this `PollAnswer` entails.
    var option: String
    
    /// Creates a new `PollAnswer`.
    init(id: Int? = nil, option: String) {
        self.id = id
        self.option = option
    }
}

/// Allows `PollAnswer` to be used as a dynamic migration.
extension PollAnswer: Migration { }

/// Allows `PollAnswer` to be encoded to and decoded from HTTP messages.
extension PollAnswer: Content { }

/// Allows `PollAnswer` to be used as a dynamic parameter in route definitions.
extension PollAnswer: Parameter { }

extension PollAnswer: Validatable {
    static func validations() throws -> Validations<PollAnswer> {
        var validations = Validations(PollAnswer.self)
        try validations.add(\.option, .count (2...10))
        return validations
    }
}
