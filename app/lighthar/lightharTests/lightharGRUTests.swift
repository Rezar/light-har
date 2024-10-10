/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest
import CoreML

final class LightHarGRUTests: XCTestCase {

    var model: MLModel?
    var modelOutput: String = "linear_24"
    var ttl: Double = 10.0

    override func setUpWithError() throws {
        model = nil
    }

    override func tearDownWithError() throws {
        model = nil
    }

    /// Generalized method for running model predictions for a specified duration.
    func modelPrediction(ttl: Double, createModelInput: @escaping (MLMultiArray) -> MLFeatureProvider) throws {
        let expectation = self.expectation(description: "Running model for \(ttl) seconds")
        let endTime = Date().addingTimeInterval(ttl)
        let inputArray = try MLMultiArray(shape: [1, 16, 3], dataType: .float32)

        DispatchQueue.global().async {
            while Date() < endTime {
                // Generate random input data
                for i in 0..<16 {
                    let iNumber = NSNumber(value: i)
                    inputArray[[0, iNumber, 0]] = NSNumber(value: Float.random(in: -1.0...1.0)) // X-axis
                    inputArray[[0, iNumber, 1]] = NSNumber(value: Float.random(in: -1.0...1.0)) // Y-axis
                    inputArray[[0, iNumber, 2]] = NSNumber(value: Float.random(in: -1.0...1.0)) // Z-axis
                }

                let modelInput = createModelInput(inputArray)

                do {
                    guard let model = self.model else {
                        DispatchQueue.main.async {
                            XCTFail("Model failed to load.")
                        }
                        expectation.fulfill()
                        return
                    }
                    let output = try model.prediction(from: modelInput)

                    if let outputArray = output.featureValue(for: self.modelOutput)?.multiArrayValue {
                        var maxValue: Float = outputArray[0].floatValue
                        for i in 1..<outputArray.count {
                            let value = outputArray[i].floatValue
                            if value > maxValue {
                                maxValue = value
                            }
                        }
                        XCTAssertTrue(maxValue >= 0, "Model output should be non-negative.")
                    } else {
                        DispatchQueue.main.async {
                            XCTFail("Failed to get model output.")
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        XCTFail("Error making prediction: \(error)")
                    }
                }
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: ttl + 5.0, handler: nil)
    }

    /// Measures the performance of a block of code.
    private func measurePerformance(block: @escaping () throws -> Void) {
        let clockMetric = XCTClockMetric()
        let memoryMetric = XCTMemoryMetric()
        let cpuMetric = XCTCPUMetric()
        let measureOptions = XCTMeasureOptions()
        let energyMetric = EnergyMetric()
        let consumptionMetric = EnergyConsumptionMetric()
        measureOptions.iterationCount = 10  // Reduced iteration count to avoid long test times

        let metrics: [XCTMetric] = [clockMetric, memoryMetric, cpuMetric, energyMetric, consumptionMetric]

        measure(metrics: metrics, options: measureOptions) {
            do {
                try block()
            } catch {
                XCTFail("Error during performance measurement: \(error)")
            }
        }
    }


    func testGRU() {
        model = try? GRU().model
        measurePerformance {
            try self.modelPrediction(ttl: self.ttl) { inputArray in
                GRUInput(x: inputArray)
            }
        }
    }
    
    func testGRUInt8LSQuantization() {
        model = try? GRUInt8LSQuantization().model
        measurePerformance {
            try self.modelPrediction(ttl: self.ttl) { inputArray in
                GRUInt8LSQuantizationInput(x: inputArray)
            }
        }
    }

    func testGRUMagnitudePruner() {
        model = try? GRUMagnitudePruner().model
        measurePerformance {
            try self.modelPrediction(ttl: self.ttl) { inputArray in
                GRUMagnitudePrunerInput(x: inputArray)
            }
        }
    }

    func testGRUPalettizationLUT() {
        model = try? GRUPalettizationLUT().model
        measurePerformance {
            try self.modelPrediction(ttl: self.ttl) { inputArray in
                GRUPalettizationLUTInput(x: inputArray)
            }
        }
    }

    func testGRUThresholdPruner() {
        model = try? GRUThresholdPruner().model
        measurePerformance {
            try self.modelPrediction(ttl: self.ttl) { inputArray in
                GRUThresholdPrunerInput(x: inputArray)
            }
        }
    }
}
