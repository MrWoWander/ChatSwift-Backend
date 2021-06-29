//
//  WebSocketConnectionModel.swift
//  
//
//  Created by Mikhail Ivanov on 29.06.2021.
//

import Vapor

struct WebSocketConnectionModel {
    var id: UUID
    var socket: WebSocket
    var userId: UUID
}
