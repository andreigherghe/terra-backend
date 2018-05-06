//
//  Poll.swift
//  App
//
//  Created by Andrei GHERGHE on 05/05/2018.
//

import FluentSQLite
import Vapor

/// A single entry of a Poll list.
final class Poll: SQLiteModel {
    /// The unique identifier for this `Poll`.
    var id: Int?
    
    /// `Poll` question.
    var question: String
    
    /// The start date of the `Poll`.
    var startDate: Double?
    
    // The end date of the `Poll`.
    var endDate: Double
    
    // The result showing time of the `Poll`.
    var showResultsDate: Double?
    
    // If the results are to be displayed immediately after voting in the `Poll`.
    var showResultsImmediately: Int?
    
    // If comments are allowed in the `Poll`.
    var disableComments: Int?
    
    /// Creates a new `Poll`.
    init?(id: Int? = nil,
         question: String,
         startDate: Double?,
         endDate: Double,
         showResultsDate: Double?,
         showResultsImmediately: Int?,
         disableComments: Int?) {
        
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

    var answers: Children<Poll, PollAnswer> {
        return children(\.pollID)
    }
}

extension Poll: Validatable {
    static func validations() throws -> Validations<Poll> {
        var validations = Validations(Poll.self)
        try validations.add(\.question, .count (5...25))
        return validations
    }
}
