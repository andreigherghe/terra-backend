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

    func getResultsForPoll(pollID: UUID, pollOptions: [PollAnswer], req: Request) throws -> [PollResultContext]? {
        var results = [PollResultContext]()

        for option in pollOptions {
            guard let optionID = option.id else {
                throw Abort(.internalServerError)
            }
            let voteCount = try PollVote.query(on: req).filter(\PollVote.pollID == pollID).filter(\PollVote.optionID == option.id).count().wait()
            let result = PollResultContext(pollID: pollID, optionID: optionID, votes: voteCount)
            results.append(result)
        }

        return results.count > 0 ? results : nil
    }

    func index(_ req: Request) throws -> Future<[PollContext]> {
        //TODO: refactor without promise
        return Poll.query(on: req).all().flatMap(to: [PollContext].self) { polls in
            let promise = req.eventLoop.newPromise([PollContext].self)
            DispatchQueue.global().async {
                do {
                    let pollMap = try polls.compactMap { poll -> PollContext? in
                        var votedID: PollAnswer.ID?
                        guard let pollID = poll.id else {
                            throw Abort(.internalServerError)
                        }
                        if let user = req.user() {
                            if let votes = try? poll.votes.query(on: req).filter(\PollVote.userID == user.id).filter(\PollVote.pollID == poll.id).all().wait() {
                                if (votes.count > 2) {
                                    throw Abort(.internalServerError)
                                }
                                if (votes.count == 1) {
                                    votedID = votes[0].optionID
                                }

                            }
                        }
                        let pollOptions = try poll.options.query(on: req).all().wait()
                        let results = try self.getResultsForPoll(pollID: pollID, pollOptions: pollOptions, req: req)
                        return PollContext(poll: poll, options: pollOptions, votedID: votedID, results: results)
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
    func create(_ req: Request) throws -> Future<Response> {
        let poll = req.content.get(Poll.self, at: "poll")
        let answerArray = req.content.get([String].self, at: "options")

        let answers = answerArray.flatMap { answerMap -> Future<[PollAnswer]> in
            Future.map(on:req) {
                answerMap.compactMap { answer in
                    if (answer.isEmpty) {
                        return nil
                    }
                    return PollAnswer(option: answer)
                }
            }
        }
        
        return flatMap(to: Response.self, poll, answers) { (savedPoll, children) in
            //TODO: use parameters instead of hardcoded urls
            if (children.count < 2){
                return Future.map(on: req) {req.redirect(to: "/?createPollSuccess=false")}
            }
            try savedPoll.validate()
            for child in children {
                try child.validate()
            }
            return savedPoll.options.attach(on: req, children, parentIdKeyPath: \.pollID).map(to: Response.self) { savedPollOptions in
                let pollContext = PollContext(poll: savedPoll, options: savedPollOptions, votedID: nil, results: nil)
                let pollJson = try JSONEncoder().encode(pollContext)
                if let pollString = String(data: pollJson, encoding: .utf8) {
                    sharedTerraSocket.broadcast(message: pollString)
                }
                return req.redirect(to: "/?createPollSuccess=true")
            }
        }
    }
    
    /// Deletes a parameterized `Poll`.
    func delete(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(Poll.self).flatMap { poll -> Future<Response> in
            let deletePoll = poll.delete(on: req)
            let deleteOptions = try poll.options.query(on: req).delete()
            let deleteComments = try poll.comments.query(on: req).delete()
            let deleteVotes = try poll.votes.query(on: req).delete()
            return flatMap(to: Response.self, deleteComments, deleteOptions, deleteVotes, deletePoll) {
                (_, _, _, _) in
                return Future.map(on: req) {req.redirect(to: "/")}
            }
        }
    }
    
    //MARK: Comments
    
    /// Adds a `PollComment` to a `Poll`
    func createComment(_ req: Request) throws -> Future<PollComment> {
        return try req.parameters.next(Poll.self).flatMap { poll in
            return try req.content.decode(PollComment.self).flatMap { comment in
                guard let userID = req.user()?.id else {
                    throw(Abort.init(.badRequest))
                }
                comment.userID = userID
                try comment.validate()
                return poll.comments.attach(on: req, [comment], parentIdKeyPath: \.pollID).flatMap { savedCommentArray in
                    guard let savedComment = savedCommentArray.first else {
                        throw(Abort(.badRequest))
                    }
                    return Future.map(on: req) { savedComment }
                }
            }
        }
    }
    
    /// Gets all `PollComment`s from a `Poll`
    func indexComment(_ req: Request) throws -> Future<[PollCommentContext]> {
        return try req.parameters.next(Poll.self).flatMap { poll in
             try poll.comments.query(on: req).all().flatMap { comments in
                let promise = req.eventLoop.newPromise([PollCommentContext].self)
                DispatchQueue.global().async {
                    do {
                        let commentContexts = try comments.compactMap { comment -> PollCommentContext in
                            let author = try comment.user.get(on: req).wait()
                            return PollCommentContext(comment: comment, author: author.email)
                        }
                        promise.succeed(result: commentContexts)
                    }
                    catch {
                        promise.fail(error: error)
                    }
                }
                return promise.futureResult
            }
        }
    }

    //MARK: Votes

    func votePoll(_ req: Request) throws -> Future<HTTPResponse> {
        return try req.parameters.next(Poll.self).flatMap { poll in
            return try req.parameters.next(PollAnswer.self).flatMap { option in
                guard let userID = req.user()?.id else {
                    throw(Abort.init(.badRequest))
                }
                guard let pollID = poll.id else {
                    throw(Abort.init(.badRequest))
                }
                guard let optionID = option.id else {
                    throw(Abort.init(.badRequest))
                }

                return try poll.options.query(on: req).filter(\PollAnswer.id == optionID).count().flatMap { answerCount -> Future<HTTPResponse> in
                    if (answerCount == 0) {
                        // TODO: add reason
                        throw Abort(.badRequest)
                    }
                    if (answerCount != 1) {
                        throw Abort(.internalServerError)
                    }
                    return try PollVote.query(on: req).filter(\PollVote.pollID == pollID).filter(\PollVote.userID == userID).count().flatMap() { votedCount -> Future<HTTPResponse> in
                        if (votedCount > 0) {
                            throw Abort(.conflict)
                        }
                        
                        let pollVote = PollVote(pollID: pollID, optionID: optionID, userID: userID)
                        return poll.votes.attach(on: req, [pollVote], parentIdKeyPath: \.pollID).transform(to: HTTPResponse(status: .created))
                    }
                }
            }
        }
    }
}

struct PollResultContext: Content {
    let pollID: Poll.ID
    let optionID: PollAnswer.ID
    let votes: Int
}

struct PollContext: Content {
    let poll: Poll
    let options: [PollAnswer]
    let votedID: PollAnswer.ID?
    let results: [PollResultContext]?
}

struct PollCommentContext: Content {
    let comment: PollComment
    let author: String
}
