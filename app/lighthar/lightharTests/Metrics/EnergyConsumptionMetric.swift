/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

class EnergyConsumptionMetric: NSObject, XCTMetric {
    private var startCPUTime: TimeInterval = 0
    private var endCPUTime: TimeInterval = 0
    private let lock = NSLock()

    func willBeginMeasuring() {
        lock.lock()
        defer { lock.unlock() }
        startCPUTime = getProcessCPUTime()
    }

    func didStopMeasuring() {
        lock.lock()
        defer { lock.unlock() }
        endCPUTime = getProcessCPUTime()
    }

    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }

    func reportMeasurements(from startTime: XCTPerformanceMeasurementTimestamp, to endTime: XCTPerformanceMeasurementTimestamp) throws -> [XCTPerformanceMeasurement] {
        lock.lock()
        defer { lock.unlock() }

        let cpuTimeDiff = endCPUTime - startCPUTime
        let energySpent = estimateEnergyConsumption(cpuTimeInSeconds: cpuTimeDiff)
        let measurement = Measurement(value: energySpent, unit: Unit(symbol: "mAh"))

        return [XCTPerformanceMeasurement(identifier: "bu.research.lighthar.EnergyConsumptionMetric", displayName: "Energy Consumption", value: measurement)]
    }

    private func getProcessCPUTime() -> TimeInterval {
        var kr: kern_return_t
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        kr = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kr == KERN_SUCCESS {
            return TimeInterval(taskInfo.user_time.seconds + taskInfo.system_time.seconds)
                + TimeInterval(taskInfo.user_time.microseconds + taskInfo.system_time.microseconds) / 1_000_000
        } else {
            return 0
        }
    }

    /**
     Estimates the energy consumption based on CPU time.

     - Parameter cpuTimeInSeconds: The CPU time used by the process in seconds.
     - Returns: Estimated energy consumption in milliamp-hours (mAh).
     */
    private func estimateEnergyConsumption(cpuTimeInSeconds: TimeInterval) -> Double {
        // Average CPU power consumption in watts (this is a rough estimate)
        let averageCPUPower = 1.5 // You may adjust this value based on device specifications

        // Voltage of the device battery (typical value for mobile devices)
        let batteryVoltage = 3.7

        // Energy in watt-hours
        let energyInWh = (averageCPUPower * cpuTimeInSeconds) / 3600

        // Convert energy to mAh
        let energyInmAh = (energyInWh / batteryVoltage) * 1000

        return energyInmAh
    }
}
