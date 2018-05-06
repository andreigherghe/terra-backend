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
    var startDate: Double
    
    // The end date of the `Poll`.
    var endDate: Double
    
    // The result showing time of the `Poll`.
    var showResultsDate: Double?
    
    // If the results are to be displayed immediately after voting in the `Poll`.
    var showResultsImmediately: Bool?
    
    // If comments are allowed in the `Poll`.
    var allowComments: Bool?
    
    /// Creates a new `Poll`.
    init?(id: Int? = nil,
         question: String,
         start_date: Double?,
         end_date: Double,
         show_results_date: Double?,
         show_results_immediately: Bool?,
         allow_comments: Bool?) {
        
        if (show_results_immediately == true && show_results_date != nil) {
            return nil
        }
                
        self.id = id
        self.question = question
        self.startDate = start_date ?? Date().timeIntervalSince1970
        self.endDate = end_date
        self.showResultsDate = show_results_date ?? end_date
        self.showResultsImmediately = show_results_immediately ?? false
        self.allowComments = allow_comments ?? true
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
