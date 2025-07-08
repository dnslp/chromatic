import SwiftUI

func MicrophoneAccessAlert() -> Alert {
    Alert(
        title: Text("No microphone access"),
        message: Text(
            """
            Please grant microphone access in the Settings app in the "Privacy ⇾ Microphone" section.
            """
        )
    )
}

struct MicrophoneAccessAlert_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper()
    }

    struct PreviewWrapper: View {
        @State private var showAlert = true
        var body: some View {
            Text("Preview for MicrophoneAccessAlert")
                .alert(isPresented: $showAlert) {
                    MicrophoneAccessAlert()
                }
        }
    }
}
