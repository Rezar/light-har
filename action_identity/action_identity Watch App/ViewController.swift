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
//    @Published private var outputIntNum = 3
    @Published var outputIntNum = 3
    @Published var outputText = "None"
    @Published var outputFloatNum: Float = 3.0
    let shape: [NSNumber]
    var inputArray = try? MLMultiArray(shape: [1, 16, 3], dataType: .float32)
    var test = 1


    
//    @Published private var IdentifiedAction = getTextPrediction(output_num: outputIntNum)

//    // transfer model output into MLMultiArray type
//    func getMultiArray(from output: GRUModelOutput) -> MLMultiArray? {
//        return output.featureValue(for: "output")?.multiArrayValue
//    }
    init() {
        self.shape = [1, 16, 3]
        self.inputArray = createOriginalMatrix(shape: self.shape, inputArray: self.inputArray!)
        self.outputIntNum = 0
        self.outputText = "Waiting for Identifing"
//        self.example = runExample(_num: 1)
//        self.outputFloatNum = runExample(_x: x,_y: y,_z: z)
        self.test = 0
        
    }
    
    
    //the the text of identified action
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

    // get the index of max value
    //because the original output of the model is an array of prediction property, and the index of the max value of the array is the identified class number.
    //we will first get the class number, then transfer it into class name
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
    
    //create original matrix
    func createOriginalMatrix(shape: [NSNumber], inputArray: MLMultiArray) -> MLMultiArray{
        for i in 0..<shape[0].intValue {
                    for j in 0..<shape[1].intValue {
                        for k in 0..<shape[2].intValue {
                            let index = i * shape[1].intValue * shape[2].intValue + j * shape[2].intValue + k
                            inputArray[index] = NSNumber(value: Float.random(in: -20...20)) // 用随机值填充数组
                        }
                    }
                }
        return inputArray
    }
    
    
    //Run method: renew the input and get numerical output
    func predict(x: Float, y:Float, z:Float, multiArray: MLMultiArray, shape:[NSNumber]) -> String {

        // accept a set of new data，for example: [1, 2, 3]
        let newData: [Float] = [x, y, z]
        
        // move every set of xyz one seat ahead
        for i in 0..<(shape[1].intValue - 1) {
            let currentIndex = i * shape[2].intValue
            let nextIndex = (i + 1) * shape[2].intValue
            
            multiArray[currentIndex] = multiArray[nextIndex]
            multiArray[currentIndex + 1] = multiArray[nextIndex + 1]
            multiArray[currentIndex + 2] = multiArray[nextIndex + 2]
        }
        
        // add the new set of xyz to the inputArray
        let lastIndex = (shape[1].intValue - 1) * shape[2].intValue
        multiArray[lastIndex] = newData[0] as NSNumber
        multiArray[lastIndex + 1] = newData[1] as NSNumber
        multiArray[lastIndex + 2] = newData[2] as NSNumber

        var maxIndex = 100
        do {
            let modelInput = GRUModelInput(gru_4_input: inputArray!)
            let modelOutput = try model?.prediction(input: modelInput)
            //output.identity--get the original output from the model
            //and it would be [.x,.y,.z,.q,.w,.e], the index with largest property is the identified class
            let outputMultiArray = modelOutput?.Identity
            
            maxIndex = getIndexOfMaxValue(from: outputMultiArray!)
            outputText = getTextPrediction(output_num: maxIndex)

        } catch {
            print("Error: \(error.localizedDescription)")
        }
        
        return outputText
    }
    
    //test renew matrix function
    func printMLMatrix(matrix: MLMultiArray)->Int{
        for i in 0..<shape[0].intValue {
                    for j in 0..<shape[1].intValue {
                        for k in 0..<shape[2].intValue {
                            let index = i * shape[1].intValue * shape[2].intValue + j * shape[2].intValue + k
                            print(matrix[index])
                        }
                    }
                }
        return 0
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
    
// //used to test the model identify performance
//        for i in 0..<shape[0].intValue {
//                    for j in 0..<shape[1].intValue {
//                            let index1 = i * shape[1].intValue * shape[2].intValue + j * shape[2].intValue + 0
//                            let index2 = i * shape[1].intValue * shape[2].intValue + j * shape[2].intValue + 1
//                            let index3 = i * shape[1].intValue * shape[2].intValue + j * shape[2].intValue + 2
//                            inputArray![index1] = NSNumber(value: 2)
//                            inputArray![index2] = NSNumber(value: 9)
//                        inputArray![index3] = NSNumber(value: 1)
//
//                    }
//                }
    
    
//        var maxIndex = 100
//        do {
//            let modelInput = GRUModelInput(gru_4_input: inputArray!)
//            let modelOutput = try model?.prediction(input: modelInput)
//            //output.identity--get the original output from the model
//            //and it would be [.x,.y,.z,.q,.w,.e], the index with largest property is the identified class
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
    
//    //convert To MLMultiArray And Get MaxIndex
//    func result(acceleration: AccelerometerData) -> Int {
//        //Transfer accelerometer data type into mlmultiarray
//        //so that the model can accept the data
//        let shape: [NSNumber] = [1, 16, 3]
//        let inputArray = try? MLMultiArray(shape: shape, dataType: .float32)
//        for i in 0..<shape[0].intValue {
//            for j in 0..<shape[1].intValue {
//                for k in 0..<shape[2].intValue {
//                    let index = i * shape[1].intValue * shape[2].intValue + j * shape[2].intValue + k
//                    switch k{
//                    case 0: inputArray![index] = NSNumber(value: acceleration.recentData[j].x)
//                    case 1: inputArray![index] = NSNumber(value: acceleration.recentData[j].y)
//                    case 2: inputArray![index] = NSNumber(value: acceleration.recentData[j].z)
//                    default:
//                        print("Error in transfering data type")
//                    }
//
//                }
//            }
//        }
//        var maxIndex = 100
//        //use model to get prediction
//        do {
//            let modelInput = GRUModelInput(gru_4_input: inputArray!)
//            let modelOutput = try model?.prediction(input: modelInput)
//            let outputMultiArray = modelOutput?.Identity
//            maxIndex = getIndexOfMaxValue(from: outputMultiArray!)
//
//        } catch {
//            print("Error: \(error.localizedDescription)")
//        }
//        return maxIndex
//    }
}




//Get raw acceleraometer data

//import Foundation
//import CoreMotion
//import Combine
//
//class AccelerometerData: ObservableObject {
//    @Published var recentData: [CMAcceleration] = []
//
//    private let motionManager = CMMotionManager()
//    private let maxDataPoints = 16
//
//    init() {
//        if motionManager.isAccelerometerAvailable {
//            motionManager.accelerometerUpdateInterval = 0.1
//
//            motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
//                if let acceleration = data?.acceleration {
//                    DispatchQueue.main.async {
//                        self.add(acceleration)
//                    }
//                } else if let error = error {
//                    print("Error: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//
//    private func add(_ acceleration: CMAcceleration) {
//        recentData.append(acceleration)
//
//        if recentData.count > maxDataPoints {
//            recentData.removeFirst()
//        }
//    }
//
//    deinit {
//        motionManager.stopAccelerometerUpdates()
//    }
//}




