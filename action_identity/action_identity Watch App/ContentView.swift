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
                GRUView(isShowing: $isShowingGRUView)
            }
        }
    }

}

struct GRUView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var gruPredictor = gru_predictor()
    
    @ObservedObject var accelerometerData = AccelerometerData()
    
//There are some error from getting accelerometer data，So I temporarily commented out this line of code
//    let output_num = gruPredictor.result(acceleration: accelerometerData)

//    set an example
        var output_num: Int {
    //        return gruPredictor.result(acceleration: accelerometerData)
            let range = 0...5
            return range.randomElement()!
        }
//    let output = getTextPrediction(output_num: output_num)

    @Binding var isShowing: Bool

    var body: some View {
        VStack {
            Text(getTextPrediction(output_num: output_num))
            Button(action: {
                isShowing = false
            }) {
                Text("Back to Model Options")
            }
        }
        .navigationBarTitle("GRU View")
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
