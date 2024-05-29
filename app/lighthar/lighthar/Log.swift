/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */
import Foundation

struct Log: Identifiable {
    let id = UUID()
    let timestamp: Date
    let activity: String
    let maxValue: Float
    let memoryUsage: String
    let batteryUsage: String
}
