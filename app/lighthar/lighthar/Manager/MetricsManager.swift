/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */

import MetricKit

class MetricsManager: NSObject, MXMetricManagerSubscriber, ObservableObject {
    override init() {
        super.init()
        MXMetricManager.shared.add(self)
    }
    
    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            print(payload.jsonRepresentation())
            if let energyMetric = payload.cpuMetrics {
               print("Total Energy Consumed: \(energyMetric.cumulativeCPUTime)")
           }
        }
    }
    
    deinit {
        MXMetricManager.shared.remove(self)
    }
}

