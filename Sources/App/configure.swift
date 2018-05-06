import FluentSQLite
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentSQLiteProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
    let sqlite = try SQLiteDatabase(storage: .memory)

    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Todo.self, database: .sqlite)
    migrations.add(model: Poll.self, database: .sqlite)
    migrations.add(model: PollAnswer.self, database: .sqlite)
    services.register(migrations)

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
