//
//  EnergyObserver.swift
//  Calories
//
//  Created by MacBook Pro M1 on 2022/02/21.
//

import HealthKit
import SwiftUI
import OSLog

private let healthLogger = Logger(subsystem: "com.github.lunf.zShellWatch", category: "Health")

struct HealthHRV{
    var hrv: Int
    var color: Color

    init(hrv: Int, color: Color) {
        self.hrv = hrv
        self.color = color
    }

    init(){
        self.hrv = -1
        self.color = Color.green
    }

    init(hrv: Int){
        self.hrv = hrv
        self.color = Color.green
    }
}

struct HealthInfo {
    var steps: Int
    var excercise: Int
    var excerciseTime: Int
    var standHours: Int
    var heartRate: Int
    var hrv: HealthHRV

    init(steps: Int, excercise: Int, excerciseTime: Int, standHours: Int, heartRate: Int, hrv: HealthHRV) {
        self.steps = steps
        self.excercise = excercise
        self.excerciseTime = excerciseTime
        self.standHours = standHours
        self.heartRate = heartRate
        self.hrv = hrv
    }

    init(){
        self.init(steps: 0, excercise: 0, excerciseTime: 0, standHours: 0, heartRate: 0, hrv: HealthHRV())
    }

    func description() -> String {
        return "Steps:  \t\(steps)\n"
            +  "excercise:  \t\(excercise)\n"
            +  "excerciseTime:  \t\(excerciseTime)\n"
            +  "standHours:  \t\(standHours)\n"
            +  "heartRate:  \t\(heartRate)\n"
    }

}

// MARK: - HealthObserver
class HealthObserver {
    let userdefaults = qUserdefaults

    /// - Tag: Health Store
    let healthStore: HKHealthStore

    let hkDataTypesOfInterest = Set([
        HKObjectType.activitySummaryType(),
        HKCategoryType.categoryType(forIdentifier: .appleStandHour)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
    ])

    var lastHRV: Int{
        didSet{
            userdefaults?.set(lastHRV, forKey: "lastHRV")
        }
    }
    private var didRequestAuthorization = false

    init() {
        self.healthStore = HKHealthStore()
        lastHRV = userdefaults?.integer(forKey: "lastHRV") ?? 0
    }

    func requestAuthorizationIfNeeded() {
        guard qUseHealthKit, !didRequestAuthorization else {
            return
        }

        didRequestAuthorization = true
        healthStore.requestAuthorization(toShare: nil, read: hkDataTypesOfInterest) { result,error in
            healthLogger.info("Health authorization result: \(result.description, privacy: .public) \(error?.localizedDescription ?? "", privacy: .public)")
        }
    }

    func fetchSample(quantityType: HKQuantityType, unit: HKUnit, completion: @escaping (Int) -> ()){

        let predicate = HKQuery.predicateForSamples(
          withStart: .distantPast,
          end: Date(),
          options: .strictEndDate
        )

        let sortDescriptors: [NSSortDescriptor]? = [NSSortDescriptor(
          key: HKSampleSortIdentifierStartDate,
          ascending: false
        )]

        let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: 1, sortDescriptors: sortDescriptors) {
            (query, results, error) in
            if error != nil {
                healthLogger.error("Health sample query failed: \(error.debugDescription, privacy: .public)")
                   // Handle error
                completion(-1)
            } else if let results = results {
//               for sample in results {
                if let quantitySample = results.first as? HKQuantitySample {
                   let value = quantitySample.quantity.doubleValue(for: unit)
                   completion(Int(value))
               } else {
                   completion(-1)
               }
//               }
            } else {
                completion(-1)
            }
        }
        healthStore.execute(query)
    }

    func fetchActivitySummary( completion: @escaping (HKActivitySummary) -> ()){
        let predicate = HKQuery.predicateForActivitySummary(
            with: DateComponents(components: [.year, .month, .day], date: Date())
        )
        let query = HKActivitySummaryQuery(predicate: predicate) { query, results, error in

            if error != nil {
                   // Handle error
                completion(HKActivitySummary())
            } else if let results = results {
                completion(results.first ?? HKActivitySummary())
            } else {
                completion(HKActivitySummary())
            }
        }
        healthStore.execute(query)
    }
    func subscribeToActivitySummary(sampleType: HKSampleType,completion: @escaping (_ summary: HKActivitySummary) -> Void){

        var isStop = false

        let query = HKObserverQuery(
            sampleType: sampleType,
            predicate: nil
        ) { _, _, error in
            guard error == nil else {
                healthLogger.error("Activity summary observer failed: \(error!.localizedDescription, privacy: .public)")

                return
            }
            if(!isStop){
                self.fetchActivitySummary { summary in
                    completion(summary)
                }
                isStop = true
            }

        }

        healthStore.execute(query)
    }

    func fetchStatistics(
        quantityType: HKQuantityType,
        options: HKStatisticsOptions,
        startDate: Date,
        endDate: Date,
        interval: DateComponents,
        completion: @escaping (HKStatistics) -> () ){

        let query = HKStatisticsCollectionQuery(
          quantityType: quantityType,
          quantitySamplePredicate: nil,
          options: options,
          anchorDate: startDate,
          intervalComponents: interval
        )

        query.initialResultsHandler = { query, collection, error in
            guard let statsCollection = collection else {
                return
            }

            statsCollection.enumerateStatistics(from: startDate, to: endDate) { stats, stop in
                completion(stats)
            }
        }

        healthStore.execute(query)
    }

    func subscribeToStatisticsForToday(
      forQuantityType quantityType:
      HKQuantityType,
      unit: HKUnit,
      options: HKStatisticsOptions,
      healthStore: HKHealthStore = .init(),
      completion: @escaping (Int) -> Void) {

          let query = HKObserverQuery(
            sampleType: quantityType,
            predicate: nil
          ) { _, _, error in
                guard error == nil else {
                  healthLogger.error("Statistics observer failed: \(error!.localizedDescription, privacy: .public)")

                  return
                }

                  self.fetchStatistics(quantityType: quantityType, options: options, startDate: Calendar.current.startOfDay(for: Date()) , endDate: Date(), interval: DateComponents(day: 1)) { stats in
                      let value = stats.sumQuantity()?.doubleValue(for: unit) ?? 0
                      completion(Int(value))
                  }
          }

          healthStore.execute(query)
    }
}

// MARK: - HealthObserver extension : Keep
extension HealthObserver {

    func getHealthInfo(completion: @escaping (HealthInfo) -> ()) {

        healthLogger.debug("getHealthInfo")
        guard qUseHealthKit else {
            completion(HealthInfo())
            return
        }

        requestAuthorizationIfNeeded()

        var health = HealthInfo(steps: -1, excercise: -1, excerciseTime: -1, standHours: -1, heartRate: -1, hrv: HealthHRV())
        let group = DispatchGroup()
        let stateQueue = DispatchQueue(label: "HealthObserver.healthInfo.state")

        func update(_ block: @escaping (inout HealthInfo) -> Void) {
            stateQueue.async {
                block(&health)
                group.leave()
            }
        }

        group.enter()
        getCurrentSteps { steps in
            update { $0.steps = max(steps, 0) }
        }

        group.enter()
        getActiveEnergyBurned { excercise in
            update { $0.excercise = max(excercise, 0) }
        }

        group.enter()
        getExerciseTime { excerciseTime in
            update { $0.excerciseTime = max(excerciseTime, 0) }
        }

        group.enter()
        getStandHours { standHours in
            update { $0.standHours = max(standHours, 0) }
        }

        group.enter()
        getHeartRate { heartRate in
            update { $0.heartRate = max(heartRate, 0) }
        }

        group.enter()
        getHRV { hrv in
            let safeHRV = max(hrv, 0)
            let color = safeHRV < self.lastHRV ? Color.init(r: 230, g: 50, b: 0) : Color.init(r: 0, g: 200, b: 0)
            self.lastHRV = safeHRV
            update { $0.hrv = HealthHRV(hrv: safeHRV, color: color) }
        }

        group.notify(queue: stateQueue) {
            healthLogger.debug("Health info updated: \(health.description(), privacy: .public)")
            completion(health)
        }
    }

    func getCurrentSteps(completion: @escaping (Int) -> ()) {
        let type: HKQuantityType = HKQuantityType(HKQuantityTypeIdentifier.stepCount)
        healthLogger.debug("getCurrentSteps")

        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
            if let error = error {
                healthLogger.error("Step statistics query failed: \(error.localizedDescription, privacy: .public)")
                completion(-1)
                return
            }
            let value = stats?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            completion(Int(value))
        }
        healthStore.execute(query)
    }

    func getActiveEnergyBurned(completion: @escaping(Int) -> ()){
        healthLogger.debug("getActiveEnergyBurned")

        fetchActivitySummary { summary in

            let excerciseValue = summary.activeEnergyBurned.doubleValue(
              for: HKUnit.kilocalorie()
            )
            completion(Int(excerciseValue))
        }
    }

    func getExerciseTime(completion: @escaping(Int) -> ()){
        healthLogger.debug("getExerciseTime")

        fetchActivitySummary { summary in

            let time = summary.appleExerciseTime.doubleValue(
              for: HKUnit.minute()
            )
            completion(Int(time))
        }
    }

    func getStandHours(completion: @escaping(Int) -> ()){
        healthLogger.debug("getStandHours")

        fetchActivitySummary { summary in

            let stamd = summary.appleStandHours.doubleValue(
              for: HKUnit.count()
            )
            completion(Int(stamd))
        }
    }

    func getHeartRate(completion: @escaping(Int) -> ()){
        healthLogger.debug("getHeartRate")

        fetchSample(quantityType: HKQuantityType(.heartRate), unit: HKUnit(from: "count/min"), completion: completion)
    }

    func getHRV(completion: @escaping(Int) -> ()){
        healthLogger.debug("getHRV")

        fetchSample(quantityType: HKQuantityType(.heartRateVariabilitySDNN), unit: HKUnit(from: "ms"), completion: completion)
    }
}

extension DateComponents {
  init(
    calendar: Calendar = .autoupdatingCurrent,
    components: Set<Calendar.Component>,
    date: Date
  ) {
    self = calendar.dateComponents(components, from: date)
    self.calendar = calendar
  }
}
