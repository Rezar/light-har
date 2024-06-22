/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */

import SwiftUI
import CoreMotion
import CoreML
import MetricKit

struct RunningView: View {
    var selectedModel: String
    @State private var isRunning = false
    @State private var registerAsLoop = false
    @State private var startTime = Date()
    @State private var showLogs = false
    @State private var elapsedTime = "00:00"
    @State private var accelerometerData = (x: 0.0, y: 0.0, z: 0.0)
    @State private var accelerometerReadings: [(x: Double, y: Double, z: Double)] = []
    @State private var activity = "Unknown"
    @State private var timer: Timer? = nil
    @State private var predictionCounter = 0
    @State private var predictionInterval = 60
    @State private var logs: [Log] = []
    @State private var memoryUsage: String = "-- MB"
    @State private var batteryUsage: String = "-- mAh"
    
    private let backgroundTaskManager = BackgroundTaskManager()
        
    
    let motionManager = CMMotionManager()
    @State var model: MLModel?
    @State var model_output: String?
    @State var model_input: MLFeatureProvider?
    
    let intervals = [5, 15, 30, 60, 600]

    var body: some View {
        VStack {
            HStack {
                Text("Background as Loop:")
                Toggle(isOn: $registerAsLoop) {
                    Text("")
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .disabled(isRunning)
            }
            .padding(.horizontal)
            HStack {
                Text("Prediction Interval (s):")
                Spacer()
                Picker("", selection: $predictionInterval) {
                    ForEach(intervals, id: \.self) { interval in
                        Text("\(interval)").tag(interval)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: 200)
                .disabled(isRunning)
            }
            .padding(.horizontal)
            
            HStack {
                Text("Model: \(selectedModel)")
                    .font(.headline)
                    .padding(.leading)
                Spacer()
                Button(action: {
                    showLogs = true
                }) {
                    Image(systemName: "list.bullet")
                        .padding()
                }
            }
            .padding(.top)

            VStack {
                Text("Prediction:")
                    .font(.subheadline)
                    .padding(.top)
                Text("\(activity)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
            }
            
            Text("Time: \(elapsedTime)")
                .font(.title)
                .padding(.top)
            
            VStack {
                VStack(alignment: .leading) {
                    Text("Sensor")
                        .font(.headline)
                    HStack {
                        Text("X:")
                        Spacer()
                        Text("\(accelerometerData.x, specifier: "%.2f")")
                    }
                    .padding(.top, 2)

                    HStack {
                        Text("Y:")
                        Spacer()
                        Text("\(accelerometerData.y, specifier: "%.2f")")
                    }
                    .padding(.top, 2)

                    HStack {
                        Text("Z:")
                        Spacer()
                        Text("\(accelerometerData.z, specifier: "%.2f")")
                    }
                    .padding(.top, 2)
                }
                .padding()
                .border(Color.black, width: 1)
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack {
                VStack(alignment: .leading) {
                    Text("Metrics")
                        .font(.headline)
                    HStack {
                        Text("Memory Utilization (kB):")
                        Spacer()
                        Text(memoryUsage)
                    }
                    .padding(.top, 2)
                    
                    HStack {
                        Text("Battery Usage (mAh):")
                        Spacer()
                        Text(batteryUsage)
                    }
                    .padding(.top, 2)
                }
                .padding()
                .border(Color.black, width: 1)
            }
            .padding(.horizontal)

            Spacer()
            
            HStack {
                Button(action: toggleRunning) {
                    Text(isRunning ? "Stop" : "Start")
                        .padding()
                        .background(isRunning ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: saveLogs) {
                    Text("Save Logs")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.bottom)
        }
        .onAppear(perform: {
            initModel()
            MXMetricManager.shared.add(MetricsHandler.shared)
            MetricsHandler.shared.onMemoryUsageUpdate = { memoryUsageKB in
                DispatchQueue.main.async {
                    self.memoryUsage = String(format: "%.2f", memoryUsageKB)
                }
            }
            MetricsHandler.shared.onBatteryUsageUpdate = { batteryUsage in
                DispatchQueue.main.async {
                    self.batteryUsage = String(format: "%.2f", batteryUsage)
                }
            }
        })
        .onDisappear {
            MXMetricManager.shared.remove(MetricsHandler.shared)
            MetricsHandler.shared.onMemoryUsageUpdate = nil
            MetricsHandler.shared.onBatteryUsageUpdate = nil
        }
        .navigationBarBackButtonHidden(isRunning)
        .navigationTitle("Activity Detection")
        .background(
            NavigationLink(
                destination: LogsView(model: selectedModel, logs: logs),
                isActive: $showLogs,
                label: { EmptyView() }
            )
        )
        
    }

    func initModel() {
        switch selectedModel {
        case "CNN":
            model = try? CNN().model
            model_output = "var_74"
        case "CNNInt8LSQuantization":
            model = try? CNNInt8LSQuantization().model
            model_output = "var_74"
        case "CNNMagnitudePruner":
            model = try? CNNMagnitudePruner().model
            model_output = "var_74"
        case "CNNPalettizationLUT":
            model = try? CNNPalettizationLUT().model
            model_output = "var_74"
        case "CNNThresholdPruner":
            model = try? CNNThresholdPruner().model
            model_output = "var_74"
        case "GRU":
            model = try? GRU().model
            model_output = "linear_24"
        case "GRUInt8LSQuantization":
            model = try? GRUInt8LSQuantization().model
            model_output = "linear_24"
        case "GRUMagnitudePruner":
            model = try? GRUMagnitudePruner().model
            model_output = "linear_24"
        case "GRUPalettizationLUT":
            model = try? GRUPalettizationLUT().model
            model_output = "linear_24"
        case "GRUThresholdPruner":
            model = try? GRUThresholdPruner().model
            model_output = "linear_24"
        case "LSTM":
            model = try? LSTM().model
            model_output = "linear_0"
        case "LSTMInt8LSQuantization":
            model = try? LSTMInt8LSQuantization().model
            model_output = "linear_24"
        case "LSTMMagnitudePruner":
            model = try? LSTMMagnitudePruner().model
            model_output = "linear_24"
        case "LSTMPalettizationLUT":
            model = try? LSTMPalettizationLUT().model
            model_output = "linear_24"
        case "LSTMThresholdPruner":
            model = try? LSTMThresholdPruner().model
            model_output = "linear_24"
        case "MLP":
            model = try? MLP().model
            model_output = "linear_2"
        case "MLPInt8LSQuantization":
            model = try? MLPInt8LSQuantization().model
            model_output = "linear_2"
        case "MLPMagnitudePruner":
            model = try? MLPMagnitudePruner().model
            model_output = "linear_2"
        case "MLPPalettizationLUT":
            model = try? MLPPalettizationLUT().model
            model_output = "linear_2"
        case "MLPThresholdPruner":
            model = try? MLPThresholdPruner().model
            model_output = "linear_2"
        case "Transformer":
            model = try? Transformer().model
            model_output = "linear_10"
        case "TransformerInt8LSQuantization":
            model = try? TransformerInt8LSQuantization().model
            model_output = "linear_10"
        case "TransformerMagnitudePruner":
            model = try? TransformerMagnitudePruner().model
            model_output = "linear_10"
        case "TransformerPalettizationLUT":
            model = try? TransformerPalettizationLUT().model
            model_output = "linear_10"
        case "TransformerThresholdPruner":
            model = try? TransformerThresholdPruner().model
            model_output = "linear_10"
        default:
            print("Selected model not available")
        }
    }


    func startModel() {
        isRunning = true
        startUpdates()
        backgroundTaskManager.setRegisterAsLoop(value: registerAsLoop)
        backgroundTaskManager.registerBackgroundTask()
    }

    func toggleRunning() {
        isRunning.toggle()
        if isRunning {
            startModel()
        } else {
            stopModel()
        }
    }

    func startUpdates() {
        startTime = Date()
        motionManager.startAccelerometerUpdates(to: OperationQueue.main) { data, error in
            guard let data = data else { return }
            accelerometerData = (x: data.acceleration.x, y: data.acceleration.y, z: data.acceleration.z)
            updateReadings(with: accelerometerData)
        }

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if !isRunning { timer.invalidate() }
            let currentTime = Date()
            let elapsed = currentTime.timeIntervalSince(startTime)
            elapsedTime = String(format: "%02d:%02d", Int(elapsed) / 60, Int(elapsed) % 60)
            
            predictionCounter += 1
            if predictionCounter >= predictionInterval {
                predictionCounter = 0
                makePrediction()
            }
        }
    }
    
    func simulateMetricsCollection() {
        // Simulate updating the memory and battery usage for demonstration
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.memoryUsage = "512.00" // Simulated value
            self.batteryUsage = "120.00" // Simulated value
        }
    }
    
    func stopModel() {
        isRunning = false
        motionManager.stopAccelerometerUpdates()
        timer?.invalidate()
        timer = nil
        backgroundTaskManager.endBackgroundTask()
    }

    func saveLogs() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let filename = "logs_\(selectedModel).json"
            let data = try encoder.encode(logs)
            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentDirectory.appendingPathComponent(filename)
                try data.write(to: fileURL)
                print("Logs saved to \(fileURL)")
                
                saveFileToiCloudDrive(filename: filename, data: data)
            }
        } catch {
            print("Failed to save logs: \(error)")
        }
    }

    func saveFileToiCloudDrive(filename: String, data: Data) {
        // Get the URL for the iCloud Drive Documents directory
        guard let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
            print("iCloud Drive is not available")
            return
        }
        let fileURL = iCloudURL.appendingPathComponent(filename)
        
        do {
            // Ensure the directory exists
            try FileManager.default.createDirectory(at: iCloudURL, withIntermediateDirectories: true, attributes: nil)
            
            // Write the file
            try data.write(to: fileURL)
            
            print("File saved to iCloud Drive at \(fileURL)")
        } catch {
            print("Failed to save file to iCloud Drive: \(error)")
        }
    }
    
    func updateReadings(with newReading: (x: Double, y: Double, z: Double)) {
        if accelerometerReadings.count >= 16 {
            accelerometerReadings.removeFirst()
        }
        accelerometerReadings.append(newReading)
    }

    func makePrediction() {
        guard let model = model, accelerometerReadings.count == 16 else { return }
        do {
            let inputArray = try MLMultiArray(shape: [1, 16, 3], dataType: .float32)
                
            for i in 0..<16 {
                inputArray[[0, NSNumber(value: i), 0]] = NSNumber(value: accelerometerReadings[i].x)
                inputArray[[0, NSNumber(value: i), 1]] = NSNumber(value: accelerometerReadings[i].y)
                inputArray[[0, NSNumber(value: i), 2]] = NSNumber(value: accelerometerReadings[i].z)
            }
            
           
            switch selectedModel {
            case "CNN":
                model_input = CNNInput(x: inputArray)
            case "CNNInt8LSQuantization":
                model_input = CNNInt8LSQuantizationInput(x: inputArray)
            case "CNNMagnitudePruner":
                model_input = CNNMagnitudePrunerInput(x: inputArray)
            case "CNNPalettizationLUT":
                model_input = CNNPalettizationLUTInput(x: inputArray)
            case "CNNThresholdPruner":
                model_input = CNNThresholdPrunerInput(x: inputArray)
            case "GRU":
                model_input = GRUInput(x: inputArray)
            case "GRUInt8LSQuantization":
                model_input = GRUInt8LSQuantizationInput(x: inputArray)
            case "GRUMagnitudePruner":
                model_input = GRUMagnitudePrunerInput(x: inputArray)
            case "GRUPalettizationLUT":
                model_input = GRUPalettizationLUTInput(x: inputArray)
            case "GRUThresholdPruner":
                model_input = GRUThresholdPrunerInput(x: inputArray)
            case "LSTM":
                model_input = LSTMInput(x: inputArray)
            case "LSTMInt8LSQuantization":
                model_input = LSTMInt8LSQuantizationInput(x: inputArray)
            case "LSTMMagnitudePruner":
                model_input = LSTMMagnitudePrunerInput(x: inputArray)
            case "LSTMPalettizationLUT":
                model_input = LSTMPalettizationLUTInput(x: inputArray)
            case "LSTMThresholdPruner":
                model_input = LSTMThresholdPrunerInput(x: inputArray)
            case "MLP":
                model_input = MLPInput(x: inputArray)
            case "MLPInt8LSQuantization":
                model_input = MLPInt8LSQuantizationInput(x: inputArray)
            case "MLPMagnitudePruner":
                model_input = MLPMagnitudePrunerInput(x: inputArray)
            case "MLPPalettizationLUT":
                model_input = MLPPalettizationLUTInput(x: inputArray)
            case "MLPThresholdPruner":
                model_input = MLPThresholdPrunerInput(x: inputArray)
            case "Transformer":
                model_input = TransformerInput(src_1: inputArray)
            case "TransformerInt8LSQuantization":
                model_input = TransformerInt8LSQuantizationInput(src_1: inputArray)
            case "TransformerMagnitudePruner":
                model_input = TransformerMagnitudePrunerInput(src_1: inputArray)
            case "TransformerPalettizationLUT":
                model_input = TransformerPalettizationLUTInput(src_1: inputArray)
            case "TransformerThresholdPruner":
                model_input = TransformerThresholdPrunerInput(src_1: inputArray)
            default:
                model_input = GRUInput(x: inputArray)
            }
            
             
            let output = try model.prediction(from: model_input!)

            if let outputArray = output.featureValue(for: model_output ?? "linear_10")?.multiArrayValue {
                var maxIndex = 0
                var maxValue: Float = outputArray[0].floatValue

                for i in 1..<outputArray.count {
                    let value = outputArray[i].floatValue
                    if value > maxValue {
                        maxValue = value
                        maxIndex = i
                    }
                }
                
                activity = getTextPrediction(output_num: maxIndex)
                
                let newLog = Log(
                    timestamp: Date(),
                    activity: activity,
                    maxValue: maxValue,
                    memoryUsage: self.memoryUsage,
                    batteryUsage: self.batteryUsage
                )
                logs.append(newLog)
            }
        } catch {
            print("Error making prediction: \(error)")
        }
    }
    
    func getTextPrediction(output_num: Int) -> String {
        switch output_num {
        case 0:
            return "Walking"
        case 1:
            return "Jogging"
        case 2:
            return "Upstairs"
        case 3:
            return "DownStairs"
        case 4:
            return "Sitting"
        case 5:
            return "Standing"
        default:
            return "Waiting for Identifying"
        }
    }
    
}


struct RunningView_Previews: PreviewProvider {
    static var previews: some View {
        RunningView(selectedModel: "GRU")
    }
}
