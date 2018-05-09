import Vapor
import Authentication
import Crypto

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let tokenMiddleware = User.tokenAuthMiddleware(database: .sqlite)
    let tokenAuthedGroup = router.grouped(tokenMiddleware)
    
    let passwordMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
    let passwordAuthedGroup = router.grouped(passwordMiddleware)
    
    // Configure Poll Controller
    let pollController = PollController()
    router.get("polls", use: pollController.index)
    tokenAuthedGroup.post("polls", use: pollController.create)
    tokenAuthedGroup.delete("polls", Poll.parameter, use: pollController.delete)
    
    // Poll Comments
    tokenAuthedGroup.get("polls", Poll.parameter, "comments", use: pollController.indexComment)
    tokenAuthedGroup.post("polls", Poll.parameter, "comments", use: pollController.createComment)
    tokenAuthedGroup.post("polls", Poll.parameter, "vote", PollAnswer.parameter, use: pollController.votePoll)

    // Configure User Controller
    let userController = UserController()
    passwordAuthedGroup.post("login", use: userController.login)
    router.post("signup", use: userController.signup)
}
