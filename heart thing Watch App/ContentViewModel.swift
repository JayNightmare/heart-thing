import Foundation
import Combine
import HealthKit

@MainActor
class ContentViewModel: ObservableObject {
    @Published var heartRate: Double = 0.0
    @Published var authorizationStatusDetermined = false
    @Published var authorizationDenied = false

    private let healthKitManager = HealthKitManager()
    private var cancellables = Set<AnyCancellable>()

    func start() {
        healthKitManager.authorizeHealthKit { [weak self] success, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.authorizationStatusDetermined = true
                if success {
                    self.startHeartRateUpdates()
                } else {
                    self.authorizationDenied = true
                }
            }
        }
    }

    private func startHeartRateUpdates() {
        healthKitManager.heartRatePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { heartRate in
                self.heartRate = heartRate
            })
            .store(in: &cancellables)
        
        healthKitManager.startHeartRateQuery()
    }
}
