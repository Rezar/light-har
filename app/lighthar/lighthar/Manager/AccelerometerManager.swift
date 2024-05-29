/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */

import CoreMotion
import CoreML
import SwiftUI

class AccelerometerManager: ObservableObject {
    private var motionManager: CMMotionManager
    @Published var latestMeasurements: [CMAcceleration] = []
    @Published var activity: String = "Unknown"
    private let model: CNN
    
    init() {
        self.motionManager = CMMotionManager()
        self.motionManager.accelerometerUpdateInterval = 0.05  // 20 Hz
        self.model = try! CNN()
        startAccelerometerUpdates()
    }
    
    private func startAccelerometerUpdates() {
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data else { return }
            
            // Collect data continuously but process in chunks
            self.latestMeasurements.append(data.acceleration)
            if self.latestMeasurements.count >= 16 {
                self.processData()
                self.latestMeasurements.removeFirst(16)  // Keep the buffer sliding
            }
        }
    }
    
    private func processData() {
        guard latestMeasurements.count >= 16 else { return }
        
        // Prepare the input for the model
        do {
            let inputArray = try MLMultiArray(shape: [1, 3, 16], dataType: .float32)
            for i in 0..<16 {
                inputArray[i * 3] = NSNumber(value: latestMeasurements[i].x)
                inputArray[i * 3 + 1] = NSNumber(value: latestMeasurements[i].y)
                inputArray[i * 3 + 2] = NSNumber(value: latestMeasurements[i].z)
            }
            
            // Make prediction
            let input = CNNInput(x: inputArray)
            let modelOutput = try model.prediction(input: input)
            DispatchQueue.main.async {
                let result = modelOutput.var_75
                let maxIndex = self.getIndexOfMaxValue(from: result)
                let outputText = self.getTextPrediction(output_num: maxIndex)
                self.activity = outputText
            }
        } catch {
            print("Error preparing data or making prediction: \(error)")
        }
    }
    
    func stopAccelerometerUpdates() {
        motionManager.stopAccelerometerUpdates()
    }
    
    func getTextPrediction(output_num: Int)->String{
        switch output_num{
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
            return "Waiting for Identifing"
        }
        
    }
    
    func getIndexOfMaxValue(from multiArray: MLMultiArray) -> Int {
        let count = multiArray.count
        var maxIndex = -1
//        var maxValue = multiArray[maxIndex].floatValue
        var maxValue : Float = 0.0

        for i in 0..<count {
            let currentValue = multiArray[i].floatValue
            if currentValue >= maxValue {
                maxValue = currentValue
                maxIndex = i
            }
        }
        
        return maxIndex
    }
}
