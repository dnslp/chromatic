import SwiftUI

struct TunerControlsView: View {
    @Binding var userF0: Double
    @Binding var selectedTransposition: Int
    @AppStorage("HidesTranspositionMenu") private var hidesTranspositionMenu = false

    private let menuHeight: CGFloat = 44 // As defined in TunerView

    var body: some View {
        HStack {
            F0SelectorView(f0Hz: $userF0) // Assuming F0SelectorView is correctly defined elsewhere
            if !hidesTranspositionMenu {
                TranspositionMenu(selectedTransposition: $selectedTransposition) // Assuming TranspositionMenu is correctly defined
                    .padding(.leading, 8)
            }
            Spacer() // Keeps controls to the leading edge
        }
        .frame(height: menuHeight)
        // Removed padding/background/cornerRadius from here,
        // as those seem to be part of the overall TunerView styling
    }
}

struct TunerControlsView_Previews: PreviewProvider {
    static var previews: some View {
        @State var mockUserF0: Double = 261.63 // C4
        @State var mockSelectedTransposition: Int = 0 // Default transposition

        TunerControlsView(
            userF0: $mockUserF0,
            selectedTransposition: $mockSelectedTransposition
        )
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Color(.systemGray6)) // Added for visibility
    }
}
