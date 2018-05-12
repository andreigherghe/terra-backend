import Vapor
import Authentication
import Crypto
import Leaf

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let passwordMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
    let passwordAuthedGroup = router.grouped(passwordMiddleware)

    let tokenMiddleware = User.tokenAuthMiddleware(database: .sqlite)
    let tokenAuthedGroup = router.grouped(tokenMiddleware)
    
    // Configure Poll Controller
    let pollController = PollController()
    router.get("polls", use: pollController.index)
    router.post("polls", use: pollController.create) // AUTH
    router.get("polls", "delete", Poll.parameter, use: pollController.delete) // AUTH
    
    // Poll Comments
    tokenAuthedGroup.get("polls", Poll.parameter, "comments", use: pollController.indexComment)
    tokenAuthedGroup.post("polls", Poll.parameter, "comments", use: pollController.createComment)
    tokenAuthedGroup.post("polls", Poll.parameter, "vote", PollAnswer.parameter, use: pollController.votePoll)

    // Configure User Controller
    let userController = UserController()
    passwordAuthedGroup.post("login", use: userController.login)
    tokenAuthedGroup.get("self", use: userController.getSelf)
    router.post("signup", use: userController.signup)

    // Leaf
    router.get { req -> Future<View> in
        let leaf = try req.make(LeafRenderer.self)
        return Poll.query(on: req).all().flatMap(to: View.self) { polls in
            let promise = req.eventLoop.newPromise(View.self)
            DispatchQueue.global().async {
                do {
                    let pollMap = try polls.compactMap { poll -> PollContext? in
                        return try PollContext(poll: poll, options: poll.options.query(on: req).all().wait())
                    }
                    let homeParams = try req.query.decode(HomeParams.self)
                    let context = HomeContext(polls: pollMap, params: homeParams)
                    try promise.succeed(result: leaf.render("home", context).wait())
                }
                catch {
                    promise.fail(error: error)
                }
            }
            return promise.futureResult
        }
    }

    struct HomeParams: Content {
        let createPollSuccess: Bool?
    }

    struct HomeContext: Codable {
        let polls: [PollContext]
        let params: HomeParams
    }
}
