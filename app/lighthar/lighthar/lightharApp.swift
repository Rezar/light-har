/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */

import SwiftUI

@main
struct lightharApp: App {
    @StateObject private var accelerometerManager = AccelerometerManager()
    @StateObject private var metricsManager = MetricsManager()
    
    var body: some Scene {
        WindowGroup {
            ModelSelectionUIView()
            .environmentObject(accelerometerManager)
        }
    }
}
