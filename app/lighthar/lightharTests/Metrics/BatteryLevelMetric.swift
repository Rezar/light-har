/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

class BatteryLevelMetric: NSObject, XCTMetric {
    public var range: Int64 = 10000
    private var startBatteryLevel: Float = 0.0
    private var endBatteryLevel: Float = 0.0

    // Start measuring: Record the initial battery level
    func willBeginMeasuring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        startBatteryLevel = UIDevice.current.batteryLevel
        self.simulateWorkload()
    }

    // Stop measuring: Record the final battery level
    func didStopMeasuring() {
        self.simulateWorkload()
        endBatteryLevel = UIDevice.current.batteryLevel
        UIDevice.current.isBatteryMonitoringEnabled = false
    }

    // Report the battery level difference as the metric
    func reportMeasurements(from startTime: XCTPerformanceMeasurementTimestamp, to endTime: XCTPerformanceMeasurementTimestamp) throws -> [XCTPerformanceMeasurement] {
     
        let batteryLevelDiff = startBatteryLevel - endBatteryLevel
        
        let measurement = Measurement(value: Double(batteryLevelDiff), unit: Unit(symbol: "%"))
        return [XCTPerformanceMeasurement(identifier: "bu.research.LightHar.batteryLevelMetric",
                                         displayName: "Battery level change",
                                         value: measurement)]
    }
   
    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    private func simulateWorkload() {
        // Simulate a workload
        let _ = (1...range).reduce(0, +)
    }
    
    
}
