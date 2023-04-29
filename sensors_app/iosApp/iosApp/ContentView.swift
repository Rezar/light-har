/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */
import SwiftUI
import shared

/**
* Handles the view model for the sensor data updates.
*/
class ViewModel: ObservableObject {

    @Published var x: Double = 0.0
    @Published var y: Double = 0.0
    @Published var z: Double = 0.0
    @Published var prediction: String = "unknown"

    let sensors: Sensors = {
        let sensors = Sensors()
        sensors.start()
        return sensors
    }()

    init() {
        self.sensors.data.watch { data in
            DispatchQueue.main.async {
                guard let data = data else { return }
                self.x = data.sensor.x
                self.y = data.sensor.y
                self.z = data.sensor.z
                // self.prediction = model.predict(x, y, z)
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel = ViewModel()
	var body: some View {
		VStack {
            Text("Acceleration:")
            Text("x: \(viewModel.x)" )
            Text("y: \(viewModel.y)" )
            Text("z: \(viewModel.z)" )
            Text("\nPrediction:")
            Text("\(viewModel.prediction)")
        }
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
