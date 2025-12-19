//
//  NetwordCheck.swift
//  Capstone_2
//
//  Created by Nicode . on 2/23/24.
//

import Foundation
import Network
import SwiftUI

class Network: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "Monitor", qos: .userInteractive)
    @Published private(set) var isConnected: Bool = false

    init() { checkConnection() }

    private func checkConnection() {
        monitor.start(queue: queue)
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
    }

    func stop() { monitor.cancel() }
}
