import HealthKit
import Combine

class HealthKitManager {
    let healthStore = HKHealthStore()
    let heartRatePublisher = PassthroughSubject<Double, Error>()

    /// Requests authorization to access HealthKit data.
    func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "com.example.heartthing", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."]))
            return
        }

        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(false, NSError(domain: "com.example.heartthing", code: 2, userInfo: [NSLocalizedDescriptionKey: "Heart Rate Type is unavailable."]))
            return
        }

        let typesToRead: Set<HKObjectType> = [heartRateType]
        healthStore.requestAuthorization(toShare: nil, read: typesToRead, completion: completion)
    }

    /// Starts a query that listens for new heart rate samples.
    func startHeartRateQuery() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        let observerQuery = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] _, completionHandler, error in
            guard let self = self else { return }
            if let error = error {
                self.heartRatePublisher.send(completion: .failure(error))
                return
            }
            self.fetchLatestHeartRateSample(completionHandler: completionHandler)
        }
        
        healthStore.execute(observerQuery)
    }

    /// Fetches the most recent heart rate sample.
    private func fetchLatestHeartRateSample(completionHandler: @escaping () -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completionHandler()
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            // Always call the completion handler.
            defer { completionHandler() }
            
            guard let self = self else { return }

            if let error = error {
                self.heartRatePublisher.send(completion: .failure(error))
                return
            }

            guard let sample = samples?.first as? HKQuantitySample else {
                return
            }
            
            // The value is in "count/min" which is beats per minute (BPM).
            let heartRate = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
            self.heartRatePublisher.send(heartRate)
        }
        
        healthStore.execute(query)
    }
}
