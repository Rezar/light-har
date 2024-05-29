/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */

import SwiftUI

struct ModelSelectionUIView: View {
    @State private var selectedModel = "GRU"

    var body: some View {
        NavigationView {
            List(models, id: \.self) { model in
                NavigationLink(destination: RunningView(selectedModel: model)) {
                    Text(model)
                        .padding()
                }
            }
            .navigationTitle("Select Model")
        }
    }
}

struct ModelSelectionUIView_Previews: PreviewProvider {
    static var previews: some View {
        ModelSelectionUIView()
    }
}
