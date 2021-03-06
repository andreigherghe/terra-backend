//
//  Poll.swift
//  App
//
//  Created by Andrei GHERGHE on 05/05/2018.
//

import FluentMySQL
import Vapor

/// A single entry of a Poll list.
final class Poll: MySQLUUIDModel {
    /// The unique identifier for this `Poll`.
    var id: UUID?
    
    /// `Poll` question.
    var question: String
    
    /// The start date of the `Poll`.
    var startDate: Double?
    
    // The end date of the `Poll`.
    var endDate: Double
    
    // The result showing time of the `Poll`.
    var showResultsDate: Double?
    
    // If the results are to be displayed immediately after voting in the `Poll`.
    var showResultsImmediately: Bool?
    
    // If comments are allowed in the `Poll`.
    var disableComments: Bool?
    
    /// Creates a new `Poll`.
    init?(id: UUID? = nil,
         question: String,
         startDate: Double?,
         endDate: Double,
         showResultsDate: Double?,
         showResultsImmediately: Bool?,
         disableComments: Bool?) {
        
        self.id = id
        self.question = question
        self.startDate = startDate
        self.endDate = endDate
        self.showResultsDate = showResultsDate
        self.showResultsImmediately = showResultsImmediately
        self.disableComments = disableComments
    }
}

/// Allows `Poll` to be used as a dynamic migration.
extension Poll: Migration { }

/// Allows `Poll` to be encoded to and decoded from HTTP messages.
extension Poll: Content { }

/// Allows `Poll` to be used as a dynamic parameter in route definitions.
extension Poll: Parameter { }

extension Poll {
    var comments: Children<Poll, PollComment> {
        return children(\.pollID)
    }

    var options: Children<Poll, PollAnswer> {
        return children(\.pollID)
    }

    var votes: Children<Poll, PollVote> {
        return children(\.pollID)
    }
}

extension Poll: Validatable {
    static func validations() throws -> Validations<Poll> {
        //TODO: TIMESTAMP VALIDATION
        var validations = Validations(Poll.self)
        try validations.add(\.question, .count (5...144))
        return validations
    }
}
