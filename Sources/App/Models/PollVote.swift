//
//  PollVote.swift
//  App
//
//  Created by Andrei GHERGHE on 10/05/2018.
//

import FluentSQLite
import Vapor

/// A single entry of a PollVote list.
final class PollVote: SQLiteModel {
    /// The unique identifier for this `PollVote`.
    var id: Int?

    /// A title describing what this `PollVote` entails.
    var pollID: Poll.ID?

    var optionID: PollAnswer.ID

    var userID: User.ID

    /// Creates a new `PollVote`.
    init(id: Int? = nil,
         pollID: Poll.ID?,
         optionID: PollAnswer.ID,
         userID: User.ID
         ) {
        self.id = id
        self.pollID = pollID
        self.optionID = optionID
        self.userID = userID
    }
}

/// Allows `PollVote` to be used as a dynamic migration.
extension PollVote: Migration { }

/// Allows `PollVote` to be encoded to and decoded from HTTP messages.
extension PollVote: Content { }

/// Allows `PollVote` to be used as a dynamic parameter in route definitions.
extension PollVote: Parameter { }
