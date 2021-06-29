//
//  WebSocketController.swift
//  
//
//  Created by Mikhail Ivanov on 29.06.2021.
//

import Vapor

class WebSocketController: RouteCollection {
    
    public var sockets: [WebSocketConnectionModel] = []
    
    func boot(routes: RoutesBuilder) throws {
        routes.webSocket("chat", ":userId") { req, wSocket in
            if let userId = req.parameters.get("userId"),
               let uuid = UUID(uuidString: userId) {

                let idConnection = UUID()
                self.sockets.append(.init(id: idConnection, socket: wSocket, userId: uuid))
                
                req.logger.info("websocket: User \(uuid.uuidString) connected. Connection ID: \(idConnection)")
                
                wSocket.onClose.map {
                    req.logger.info("websocket: connection \(idConnection) closed")
                    self.sockets.removeAll { $0.id == idConnection }
                }.whenComplete {_ in}
                
                wSocket.onText { _, message in
                    let jsonData = Data(message.utf8)
                    print(message)
                    do {
                        let mes = try JSONDecoder().decode(MessageModel.self, from: jsonData)
                        
                        self.sockets.forEach { soc in
                            if soc.userId != mes.userId {
                                soc.socket.send(message)
                            }
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }

            } else {
                req.logger.warning("websocket: Invalid user id")
                wSocket.send("Invalid user id")
                wSocket.close().whenComplete {_ in}
            }
        }
    }
}
