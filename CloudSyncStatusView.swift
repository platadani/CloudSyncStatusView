import Foundation
import SwiftUI
import CoreData

class CloudKitSyncMonitor: ObservableObject {
    @Published var syncStatus: SyncStatus = .unknown

    enum SyncStatus: String {
        case unknown = "Desconocido"
        case syncing = "Sincronizando"
        case synced = "Sincronizado"
        case error = "Error"
    }

    init() {
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main) { [weak self] notification in
                self?.handleCloudKitNotification(notification)
        }
    }

    private func handleCloudKitNotification(_ notification: Notification) {
        guard let cloudEvent = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
            return
        }

        switch cloudEvent.type {
        case .setup:
            syncStatus = .syncing
        case .import:
            syncStatus = .syncing
        case .export:
            syncStatus = .syncing
        @unknown default:
            syncStatus = .unknown
        }

        if cloudEvent.endDate != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.syncStatus = .synced
            }
        }
    }
}

struct CloudSyncStatusView: View {
    @ObservedObject var syncMonitor: CloudKitSyncMonitor

    var body: some View {
        VStack(alignment: .leading) {
            Text("iCloud sync")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(statusMessage)
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                    }


                    HStack {
                        Image(systemName: "icloud")
                        Text(syncMonitor.syncStatus == .synced ? "Synced with iCloud" : "Syncing with iCloud...")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 1)
        }
        .padding(.vertical, 5)
    }

    var statusMessage: String {
        switch syncMonitor.syncStatus {
        case .unknown:
            return "Unknown synchronization status."
        case .syncing:
            return "Synchronization with iCloud may take a few minutes to initially upload your data."
        case .synced:
            return "Your data is synchronized with iCloud."
        case .error:
            return "Unfortunately, iCloud is not the most reliable service, so problems can occur. We apologize for any inconvenience this may cause."
        }
    }
}

#Preview {
    CloudSyncStatusView(syncMonitor: .init())
}

