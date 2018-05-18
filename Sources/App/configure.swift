import FluentPostgreSQL
import Vapor
import Authentication
import Leaf

let sharedTerraSocket = TerraSocket()

class TerraSocket {
    var sockets: [WebSocket] = [WebSocket]()

    func add(socket: WebSocket) {
        sockets.append(socket)
    }

    func remove(socket: WebSocket) {
        for (index, arraySocket) in sockets.enumerated() {
            if arraySocket === socket {
                sockets.remove(at: index)
            }
        }
    }

    func broadcast(message: String) {
        for socket in sockets {
            socket.send(text: message)
        }
    }
}

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentPostgreSQLProvider())
    let psqlConfig = PostgreSQLDatabaseConfig(hostname: "10.0.1.4", port: 5432, username: "postgres", password: "126DA104-17B9-414F-A2DF-EC2C46D2CA45")
    services.register(psqlConfig)

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
    migrations.add(model: Poll.self, database: .psql)
    migrations.add(model: PollAnswer.self, database: .psql)
    migrations.add(model: PollComment.self, database: .psql)
    migrations.add(model: PollVote.self, database: .psql)
    migrations.add(model: TerraToken.self, database: .psql)
    migrations.add(model: User.self, database: .psql)
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
        sharedTerraSocket.add(socket: ws)

        ws.onClose.always {
            sharedTerraSocket.remove(socket: ws)
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
    func attach(on conn: DatabaseConnectable, _ children: [Child], parentIdKeyPath: ReferenceWritableKeyPath<Child, Int?>) -> Future<[Child]> {
        return self.parent.save(on: conn).flatMap(to: [Child].self) { (savedParent) in
            let parentId = savedParent.fluentID
            let newChildren = children.map { child -> Child in
                guard let parentId = parentId as? Int else { fatalError() }
                let newChild = child
                newChild[keyPath: parentIdKeyPath] = parentId
                return newChild
            }
            return newChildren.save(on: conn)
        }
    }
}
