import FluentMySQL
import Vapor
import Authentication
import Leaf

let pollTerraSocket = TerraSocket()
let pollResultsTerraSocket = TerraSocket()

class TerraSocket {
    let sema = DispatchSemaphore(value: 1)
    var sockets: [WebSocket] = [WebSocket]()

    func add(socket: WebSocket) {
        sema.wait()
        sockets.append(socket)
        sema.signal()
    }

    func remove(socket: WebSocket) {
        sema.wait()
        for (index, arraySocket) in sockets.enumerated() {
            if arraySocket === socket {
                sockets.remove(at: index)
            }
        }
        sema.signal()
    }

    func broadcast(message: String) {
        sema.wait()
        for socket in sockets {
            socket.send(text: message)
        }
        sema.signal()
    }
}

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentMySQLProvider())

    guard let mySqlUrl = ProcessInfo.processInfo.environment["DB_MYSQL"] else {
        throw Abort(.internalServerError)
    }
    let regex = "://(.+):(.+)@(.+):(.+)/(.+)"
    let dbComponents = mySqlUrl.capturedGroups(withRegex: regex)
    let mysqlConfig = MySQLDatabaseConfig(hostname: dbComponents[2], port: Int(dbComponents[3])!, username: dbComponents[0], password: dbComponents[1], database: dbComponents[4])
    services.register(mysqlConfig)

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Poll.self, database: .mysql)
    migrations.add(model: PollAnswer.self, database: .mysql)
    migrations.add(model: PollComment.self, database: .mysql)
    migrations.add(model: PollVote.self, database: .mysql)
    migrations.add(model: TerraToken.self, database: .mysql)
    migrations.add(model: User.self, database: .mysql)
    services.register(migrations)
    
    /// Auth
    try services.register(AuthenticationProvider())

    /// Leaf
    try services.register(LeafProvider())

    /// Websockets
    let wss = NIOWebSocketServer.default()

    // Add WebSocket upgrade support to GET /echo
    wss.get("polls") { ws, req in
        // Add a new on text callback
        pollTerraSocket.add(socket: ws)

        ws.onClose.always {
            pollTerraSocket.remove(socket: ws)
        }
    }

    wss.get("pollresults") { ws, req in
        // Add a new on text callback
        pollResultsTerraSocket.add(socket: ws)

        ws.onClose.always {
            pollResultsTerraSocket.remove(socket: ws)
        }
    }

    // Register our server
    services.register(wss, as: WebSocketServer.self)
}
extension Collection where Element: Model, Element.Database: QuerySupporting {
    func save(on conn: DatabaseConnectable) -> Future<[Element]> {
        return self.map { $0.save(on: conn) }.flatten(on: conn)
    }
}

// thanks @twof
extension Children where Parent: Model, Parent.Database: QuerySupporting {
    func attach(on conn: DatabaseConnectable, _ children: [Child], parentIdKeyPath: ReferenceWritableKeyPath<Child, UUID?>) -> Future<[Child]> {
        return self.parent.save(on: conn).flatMap(to: [Child].self) { (savedParent) in
            let parentId = savedParent.fluentID
            let newChildren = children.map { child -> Child in
                guard let parentId = parentId as? UUID else { fatalError() }
                let newChild = child
                newChild[keyPath: parentIdKeyPath] = parentId
                return newChild
            }
            return newChildren.save(on: conn)
        }
    }
}

extension String {
    func capturedGroups(withRegex pattern: String) -> [String] {
        var results = [String]()

        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            return results
        }

        let matches = regex.matches(in: self, options: [], range: NSRange(location:0, length: self.characters.count))

        guard let match = matches.first else { return results }

        let lastRangeIndex = match.numberOfRanges - 1
        guard lastRangeIndex >= 1 else { return results }

        for i in 1...lastRangeIndex {
            let capturedGroupIndex = match.range(at: i)
            let matchedString = (self as NSString).substring(with: capturedGroupIndex)
            results.append(matchedString)
        }

        return results
    }
}
