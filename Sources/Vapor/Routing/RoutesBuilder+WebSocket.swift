public struct WebSocketMaxFrameSize: ExpressibleByIntegerLiteral {
    let value: Int

    public init(integerLiteral value: Int) {
        self.value = value
    }

    public static var `default`: Self {
        self.init(integerLiteral: 1 << 14)
    }
}

extension RoutesBuilder {
    /// Adds a route for opening a web socket connection
    /// - parameters:
    ///   - path: Path components separated by commas.
    ///   - maxFrameSize: The maximum allowed frame size. See `NIOWebSocketServerUpgrader`.
    ///   - shouldUpgrade: Closure to apply before upgrade to web socket happens.
    ///       Returns additional `HTTPHeaders` for response, `nil` to deny upgrading.
    ///       See `NIOWebSocketServerUpgrader`.
    ///   - onUpgrade: Closure to apply after web socket is upgraded successfully.
    /// - returns: `Route` instance for newly created web socket endpoint
    @discardableResult
    public func webSocket(
        _ path: PathComponent...,
        maxFrameSize: WebSocketMaxFrameSize = .`default`,
        shouldUpgrade: @escaping ((Request) -> EventLoopFuture<HTTPHeaders?>) = {
            $0.eventLoop.makeSucceededFuture([:])
        },
        onUpgrade: @escaping (Request, WebSocket) -> ()
    ) -> Route {
        return self.webSocket(path, maxFrameSize: maxFrameSize, shouldUpgrade: shouldUpgrade, onUpgrade: onUpgrade)
    }

    /// Adds a route for opening a web socket connection
    /// - parameters:
    ///   - path: Array of path components.
    ///   - maxFrameSize: The maximum allowed frame size. See `NIOWebSocketServerUpgrader`.
    ///   - shouldUpgrade: Closure to apply before upgrade to web socket happens.
    ///       Returns additional `HTTPHeaders` for response, `nil` to deny upgrading.
    ///       See `NIOWebSocketServerUpgrader`.
    ///   - onUpgrade: Closure to apply after web socket is upgraded successfully.
    /// - returns: `Route` instance for newly created web socket endpoint
    @discardableResult
    public func webSocket(
        _ path: [PathComponent],
        maxFrameSize: WebSocketMaxFrameSize = .`default`,
        shouldUpgrade: @escaping ((Request) -> EventLoopFuture<HTTPHeaders?>) = {
            $0.eventLoop.makeSucceededFuture([:])
        },
        onUpgrade: @escaping (Request, WebSocket) -> ()
    ) -> Route {
        return self.on(.GET, path) { request -> Response in
            return request.webSocket(maxFrameSize: maxFrameSize, shouldUpgrade: shouldUpgrade, onUpgrade: onUpgrade)
        }
    }
}

extension Request {
    public func webSocket(
        maxFrameSize: WebSocketMaxFrameSize = .`default`,
        shouldUpgrade: @escaping ((Request) -> EventLoopFuture<HTTPHeaders?>) = {
            $0.eventLoop.makeSucceededFuture([:])
        },
        onUpgrade: @escaping (Request, WebSocket) -> ()
    ) -> Response {
        let res = Response(status: .switchingProtocols)
        res.upgrader = .webSocket(maxFrameSize: maxFrameSize, shouldUpgrade: {
            shouldUpgrade(self)
        }, onUpgrade: { ws in
            onUpgrade(self, ws)
        })
        return res
    }
}
