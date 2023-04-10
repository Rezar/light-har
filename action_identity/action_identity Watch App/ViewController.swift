//
//  ViewController.swift
//  action_identity Watch App
//
//  Created by 王诗瑜 on 4/8/23.
//

import Foundation
import CoreML

class gru_predictor: ObservableObject{
    let model = try? GRUModel(configuration: MLModelConfiguration())

//    // transfer model output into MLMultiArray type
//    func getMultiArray(from output: GRUModelOutput) -> MLMultiArray? {
//        return output.featureValue(for: "output")?.multiArrayValue
//    }

    // get the index of max value
    func getIndexOfMaxValue(from multiArray: MLMultiArray) -> Int {
        let count = multiArray.count
        var maxIndex = 0
        var maxValue = multiArray[maxIndex].floatValue
        
        for i in 1..<count {
            let currentValue = multiArray[i].floatValue
            if currentValue > maxValue {
                maxValue = currentValue
                maxIndex = i
            }
        }
        
        return maxIndex
    }


//    // test example
//    func runExample() -> Int {
//
//        let shape: [NSNumber] = [1, 16, 3]
//        let inputArray = try? MLMultiArray(shape: shape, dataType: .float32)
//        for i in 0..<shape[0].intValue {
//                    for j in 0..<shape[1].intValue {
//                        for k in 0..<shape[2].intValue {
//                            let index = i * shape[1].intValue * shape[2].intValue + j * shape[2].intValue + k
//                            inputArray![index] = NSNumber(value: Float.random(in: 0...6)) // 用随机值填充数组
//                        }
//                    }
//                }
//        var maxIndex = 100
//        do {
//            let modelInput = GRUModelInput(gru_4_input: inputArray!)
//            let modelOutput = try model?.prediction(input: modelInput)
//            let outputMultiArray = modelOutput?.Identity
//            maxIndex = getIndexOfMaxValue(from: outputMultiArray!)
//
//            // 使用 modelOutput 获取预测结果
//        } catch {
//            print("Error: \(error.localizedDescription)")
//        }
//
//        return maxIndex
//    }
    
    //convert To MLMultiArray And Get MaxIndex
    func result(acceleration: AccelerometerData) -> Int {
        //Transfer accelerometer data type into mlmultiarray
        //so that the model can accept the data
        let shape: [NSNumber] = [1, 16, 3]
        let inputArray = try? MLMultiArray(shape: shape, dataType: .float32)
        for i in 0..<shape[0].intValue {
            for j in 0..<shape[1].intValue {
                for k in 0..<shape[2].intValue {
                    let index = i * shape[1].intValue * shape[2].intValue + j * shape[2].intValue + k
                    switch k{
                    case 0: inputArray![index] = NSNumber(value: acceleration.recentData[j].x)
                    case 1: inputArray![index] = NSNumber(value: acceleration.recentData[j].y)
                    case 2: inputArray![index] = NSNumber(value: acceleration.recentData[j].z)
                    default:
                        print("Error in transfering data type")
                    }
                    
                }
            }
        }
        var maxIndex = 100
        //use model to get prediction
        do {
            let modelInput = GRUModelInput(gru_4_input: inputArray!)
            let modelOutput = try model?.prediction(input: modelInput)
            let outputMultiArray = modelOutput?.Identity
            maxIndex = getIndexOfMaxValue(from: outputMultiArray!)
            
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        return maxIndex
    }
}




//Get raw acceleraometer data

import Foundation
import CoreMotion
import Combine

class AccelerometerData: ObservableObject {
    @Published var recentData: [CMAcceleration] = []

    private let motionManager = CMMotionManager()
    private let maxDataPoints = 16

    init() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1

            motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
                if let acceleration = data?.acceleration {
                    DispatchQueue.main.async {
                        self.add(acceleration)
                    }
                } else if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func add(_ acceleration: CMAcceleration) {
        recentData.append(acceleration)

        if recentData.count > maxDataPoints {
            recentData.removeFirst()
        }
    }

    deinit {
        motionManager.stopAccelerometerUpdates()
    }
}




