//
//  WebSocketProvider.swift
//  SimpleChat
//
//  Created by Nicode . on 8/14/24.
//

import Foundation

protocol WebSocketProvider: AnyObject {
    var delegate: WebSocketProviderDelegate? { get set }
    func connect()
    func disconnect()
    func send(data: Data)
    func send(message: String)
}

protocol WebSocketProviderDelegate: AnyObject {
    func webSocketDidConnect(_ webSocket: WebSocketProvider)
    func webSocketDidDisconnect(_ webSocket: WebSocketProvider)
    func webSocket(_ webSocket: WebSocketProvider, didReceiveData data: Data)
    func webSocket(_ webSocket: WebSocketProvider, didReceiveString string: String)
}
