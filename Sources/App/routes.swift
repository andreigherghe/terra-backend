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
    router.post("polls", use: pollController.create)
    router.delete("polls", Poll.parameter, use: pollController.delete)
    
    // Poll Comments
    router.get("polls", Poll.parameter, "comments", use: pollController.indexComment)
    router.post("polls", Poll.parameter, "comments", use: pollController.createComment)
    
    // Configure User Controller
//    let userController = UserController()
    router.post("login") { req -> Future<TerraToken> in
        //        let promise = req.eventLoop.newPromise([TerraToken].self)
        //        DispatchQueue.global().async {
        let user = try req.user()
        let token = try TerraToken.generate(for: user)
        return token.save(on: req)
    }
}
