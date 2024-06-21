/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */

import MetricKit


class MetricsHandler: NSObject, MXMetricManagerSubscriber {
    static let shared = MetricsHandler()
    
    var onMemoryUsageUpdate: ((Double) -> Void)?
    var onBatteryUsageUpdate: ((Double) -> Void)?
    
    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            if let memoryMetrics = payload.memoryMetrics {
                let peakMemoryUsageKB = memoryMetrics.peakMemoryUsage.converted(to: .kilobytes).value
                onMemoryUsageUpdate?(peakMemoryUsageKB)
            }
            if let batteryMetrics = payload.cpuMetrics {
                let energyConsumption = estimateEnergyConsumption(cpuTimeInSeconds: batteryMetrics.cumulativeCPUTime.converted(to: .seconds).value)
                onBatteryUsageUpdate?(energyConsumption)
            }
        }
    }
    
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        print(payloads)
        // For this research we are not going to handle the received diagnostics
    }
}
