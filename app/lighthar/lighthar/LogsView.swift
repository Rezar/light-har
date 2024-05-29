/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */
import SwiftUI

struct LogsView: View {
    var model: String
    var logs: [Log]

    var body: some View {
        List {
            ForEach(logs.sorted(by: { $0.timestamp > $1.timestamp })) { log in
                VStack(alignment: .leading) {
                    Text("Timestamp: \(log.timestamp, formatter: DateFormatter.fullTime)")
                        .font(.subheadline)
                    Text("Activity: \(log.activity)")
                        .font(.headline)
                        .foregroundColor(.blue)
                    Text("Max Value: \(log.maxValue, specifier: "%.2f")")
                        .font(.subheadline)
                    Text("Memory Usage: \(log.memoryUsage)")
                        .font(.subheadline)
                    Text("Battery Usage: \(log.batteryUsage)")
                                            .font(.subheadline)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("\(model) Logs")
    }
}

// DateFormatter extension to format date
extension DateFormatter {
    static var fullTime: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }
}

