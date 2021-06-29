//
//  WebSocketController.swift
//  
//
//  Created by Mikhail Ivanov on 29.06.2021.
//

import Vapor

class WebSocketController: RouteCollection {
    
    private var sockets: [WebSocketConnectionModel] = []
    
    func boot(routes: RoutesBuilder) throws {
        routes.webSocket("chat", ":userId") { req, wSocket in
            if let userId = req.parameters.get("userId"),
               let uuid = UUID(uuidString: userId) {
                
                let idConnection = UUID()
                self.sockets.append(.init(id: idConnection, socket: wSocket, userId: uuid))
                
                self.updateUserCount()
                
                
                wSocket.onClose.map {
                    req.logger.info("websocket: connection \(idConnection) closed")
                    self.sockets.removeAll { $0.id == idConnection }
                    
                }.whenComplete {_ in
                    self.updateUserCount()
                }
                
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
                
                req.logger.info("websocket: User \(uuid.uuidString) connected. Connection ID: \(idConnection)")
                
            } else {
                req.logger.warning("websocket: Invalid user id")
                wSocket.send("Invalid user id")
                wSocket.close().whenComplete {_ in}
            }
        }
    }
    
    func updateUserCount() {
        sockets.forEach { model in
            model.socket.send("\(sockets.count)")
        }
    }
}
