import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    // Example of configuring a controller
    let todoController = TodoController()
    router.get("todos", use: todoController.index)
    router.post("todos", use: todoController.create)
    router.delete("todos", Todo.parameter, use: todoController.delete)
    
    // Configure Poll Controller
    let pollController = PollController()
    router.get("polls", use: pollController.index)
    router.post("polls", use: pollController.create)
    router.delete("polls", Poll.parameter, use: pollController.delete)
}
