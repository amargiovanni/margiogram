//
//  NetworkMonitor.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import Network

// MARK: - Network Monitor

/// Service for monitoring network connectivity.
@Observable
final class NetworkMonitor: @unchecked Sendable {
    // MARK: - Shared Instance

    static let shared = NetworkMonitor()

    // MARK: - Properties

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor", qos: .utility)

    var isConnected: Bool = true
    var connectionType: ConnectionType = .unknown
    var isExpensive: Bool = false
    var isConstrained: Bool = false

    // MARK: - Initialization

    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateConnectionStatus(path)
            }
        }
        monitor.start(queue: queue)
    }

    private func stopMonitoring() {
        monitor.cancel()
    }

    @MainActor
    private func updateConnectionStatus(_ path: NWPath) {
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained

        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
    }
}

// MARK: - Connection Type

enum ConnectionType: String, Sendable {
    case wifi = "WiFi"
    case cellular = "Cellular"
    case ethernet = "Ethernet"
    case unknown = "Unknown"

    var icon: String {
        switch self {
        case .wifi:
            return "wifi"
        case .cellular:
            return "antenna.radiowaves.left.and.right"
        case .ethernet:
            return "cable.connector"
        case .unknown:
            return "network"
        }
    }
}
