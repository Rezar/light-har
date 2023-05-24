//
//  ContentView.swift
//  Action Identify Watch App
//
//  Created by 王诗瑜 on 2023/1/18.
//

import CoreML
import SwiftUI


struct ContentView: View {
    @State private var isShowingGRUView = false
    
    var body: some View {
        VStack {
            Text("Choose A Model")
            Button("GRU Model") {
                isShowingGRUView = true
            }
            .sheet(isPresented: $isShowingGRUView) {
                GRUView(gruPredictor: gru_predictor(), isShowing: $isShowingGRUView)
            }
        }
    }

}

struct GRUView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var gruPredictor: gru_predictor
    

    @Binding var isShowing: Bool

    var body: some View {
        VStack {
            
            //The interval to read new xyz data in seconds
            let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            
            Text(String(gruPredictor.outputText))
                .onReceive(timer) { _ in
                    //function that is reused every interval
                    gruPredictor.outputText = gruPredictor.predict(x: 0.1, y: 0.1, z: 0.1, multiArray: gruPredictor.inputArray!, shape: gruPredictor.shape)
                    
//                    //used to test the Change of time, will show the xyz change on the counsel
//                    gruPredictor.test=gruPredictor.printMLMatrix(matrix: gruPredictor.inputArray!)
            }
            Button(action: {
                isShowing = false
            }) {
                Text("Back to Model Options")
            }
        }
        .navigationBarTitle("GRU View")
    }
}
    
    
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)
        
    }
}

















//                List {
//                    ForEach(accelerometerData.recentData.indices, id: \.self) { index in
//                        let data = accelerometerData.recentData[index]
//                        Text("Data point \(index + 1): x: \(data.x, specifier: "%.3f"), y: \(data.y, specifier: "%.3f"), z: \(data.z, specifier: "%.3f")")
//                    }
//                }




//    @StateObject var gruPredictor = gru_predictor()
    
//    @ObservedObject var accelerometerData = AccelerometerData()
//    @ObservedObject：
//    用于在视图中使用由外部提供的可观察对象。
//    您需要手动创建和传递可观察对象实例。
//    适用于在多个视图之间共享和观察同一个对象的状态。
//    当可观察对象的状态发生更改时，使用@ObservedObject的视图会自动刷新。
//    @StateObject：
//    用于在视图中创建并管理自己的对象。
//    自动为视图创建和管理对象的生命周期。
//    适用于在单个视图中创建和管理对象的状态。
//    对象的生命周期与视图的生命周期相同。
//    当视图被销毁时，@StateObject修饰的对象也会被销毁。
    
//There are some error from getting accelerometer data，So I temporarily commented out this line of code
//    let output_num = gruPredictor.result(acceleration: accelerometerData)

//    set an example
//        var output_num: Int {
//    //        return gruPredictor.result(acceleration: accelerometerData)
//            let range = 0...5
//            return range.randomElement()!
//        }
//    let output = getTextPrediction(output_num: output_num)
