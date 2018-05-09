//
//  PollController.swift
//  App
//
//  Created by Andrei GHERGHE on 05/05/2018.
//

import Vapor
import Fluent

/// Controlers basic CRUD operations on `Poll`s.
final class PollController {    
func index(_ req: Request) throws -> Future<[PollContext]> {
    return Poll.query(on: req).all().flatMap(to: [PollContext].self) { polls in
        let promise = req.eventLoop.newPromise([PollContext].self)
        DispatchQueue.global().async {
            do {
                let pollMap = try polls.compactMap { poll -> PollContext? in
                    return try PollContext(poll: poll, options: poll.options.query(on: req).all().wait())
                }
                promise.succeed(result: pollMap)
            }
            catch {
                promise.fail(error: error)
            }
        }
        return promise.futureResult
    }
}
    
    /// Saves a decoded `Poll` to the database.
    func create(_ req: Request) throws -> Future<HTTPResponse> {
        let poll = req.content.get(Poll.self, at: "poll")
        let answers = req.content.get([PollAnswer].self, at: "options")
        
        return flatMap(to: HTTPResponse.self, poll, answers) { (savedPoll, children) in
            try savedPoll.validate()
            for child in children {
                try child.validate()
            }
            return savedPoll.options.attach(on: req, children, parentIdKeyPath: \.pollID).transform(to: HTTPResponse(status: .created))
        }
    }
    
    /// Deletes a parameterized `Poll`.
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Poll.self).flatMap { Poll in
            return Poll.delete(on: req)
            }.transform(to: .ok)
    }
    
    //MARK: Comments
    
    /// Adds a `PollComment` to a `Poll`
    func createComment(_ req: Request) throws -> Future<HTTPResponse> {
        return try req.parameters.next(Poll.self).flatMap { poll in
            return try req.content.decode(PollComment.self).flatMap { comment in
                guard let userID = try req.user().id else {
                    throw(Abort.init(.badRequest))
                }
                comment.userID = userID
                return poll.comments.attach(on: req, [comment], parentIdKeyPath: \.pollID).transform(to: HTTPResponse(status: .created))
            }
        }
    }
    
    /// Gets all `PollComment`s from a `Poll`
    func indexComment(_ req: Request) throws -> Future<[PollComment]> {
        return try req.parameters.next(Poll.self).flatMap { poll in
            return try poll.comments.query(on: req).all()
        }
    }

    //MARK: Votes

    func votePoll(_ req: Request) throws -> Future<HTTPResponse> {
        return try req.parameters.next(Poll.self).flatMap { poll in
            return try req.parameters.next(PollAnswer.self).flatMap { option in
                guard let userID = try req.user().id else {
                    throw(Abort.init(.badRequest))
                }
                guard let pollID = poll.id else {
                    throw(Abort.init(.badRequest))
                }
                guard let optionID = option.id else {
                    throw(Abort.init(.badRequest))
                }

                return try PollAnswer.query(on: req).filter(\PollAnswer.id == optionID).filter(\PollAnswer.pollID == pollID).count().flatMap { answerCount -> Future<HTTPResponse> in
                    if (answerCount == 0) {
                        throw Abort(.badRequest)
                    }
                    if (answerCount != 1) {
                        throw Abort(.internalServerError)
                    }
                    let pollVote = PollVote(pollID: pollID, optionID: optionID, userID: userID)
                    return poll.votes.attach(on: req, [pollVote], parentIdKeyPath: \.pollID).transform(to: HTTPResponse(status: .created))
                }
            }
        }
    }
}

struct PollContext: Content {
    let poll: Poll
    let options: [PollAnswer]
}
