import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ in HTTPStatus.ok }

    try app.register(collection: AuthController())
}
