import Vapor
import Authentication

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let tokenMiddleware = User.tokenAuthMiddleware(database: .sqlite)
    let authedGroup = router.grouped(tokenMiddleware)
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

//    // Example of configuring a controller
//    let todoController = TodoController()
//    router.get("todos", use: todoController.index)
//    router.post("todos", use: todoController.create)
//    router.delete("todos", Todo.parameter, use: todoController.delete)
    
    // Configure Poll Controller
    let pollController = PollController()
    router.get("polls", use: pollController.index)
    authedGroup.post("polls", use: pollController.create)
    authedGroup.delete("polls", Poll.parameter, use: pollController.delete)
    
    // Poll Comments
    router.get("polls", Poll.parameter, "comments", use: pollController.indexComment)
    authedGroup.post("polls", Poll.parameter, "comments", use: pollController.createComment)
}
