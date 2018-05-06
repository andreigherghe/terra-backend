//
//  PollController.swift
//  App
//
//  Created by Andrei GHERGHE on 05/05/2018.
//

import Vapor

/// Controlers basic CRUD operations on `Poll`s.
final class PollController {
    /// Returns a list of all `Poll`s.
    //    func index(_ req: Request) throws -> Future<[Poll]> {
    //        return Poll.query(on: req).all()
    //    }
    
    
    func index(_ req: Request) throws -> Future<[PollContext]> {
        return Poll.query(on: req).all().flatMap(to: [PollContext].self) { polls in
            let promise = req.eventLoop.newPromise([PollContext].self)
            DispatchQueue.global().async {
                do {
                    let pollMap = try polls.compactMap { poll -> PollContext? in
                        return try PollContext(poll: poll, options: poll.answers.query(on: req).all().wait())
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
            return savedPoll.answers.attach(on: req, children, parentIdKeyPath: \.pollID).transform(to: HTTPResponse(status: .created))
        }
    }
    
    /// Deletes a parameterized `Poll`.
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Poll.self).flatMap { Poll in
            return Poll.delete(on: req)
            }.transform(to: .ok)
    }
    
    func getAnswers(_ req: Request) throws -> Future<[PollAnswer]> {
        return try req.parameters.next(Poll.self).flatMap(to: [PollAnswer].self) { poll in
            return try poll.answers.query(on: req).all()
        }
    }
}

struct PollContext: Content {
    let poll: Poll
    let options: [PollAnswer]
}
