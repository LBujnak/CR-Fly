import SwiftUI
import DJISDK

class GlobalData : ObservableObject {
    
    @Published var libMode = false
    @Published var fpvMode = false
    
    @Published var globalAlert = false
    @Published var alertTitle : Text = Text("")
    @Published var alertMsg : Text = Text("")
    
    @Published var sdkRegistered = false
    @Published var droneConnected = false
    
    @Published var enableBridgeMode = false //false
    @Published var bridgeAppIP = "192.168.10.42"
    @Published var rcEngineConn = false
    
    @Published var mediaFilter = 0 //0 - All, 1 - Photos, 2 - Videos
    @Published var mediaList : [DJIMediaFile] = []
    @Published var mediaSections : [[DJIMediaFile]] = []
    @Published var mediaFetched = false
    @Published var mediaPreview : DJIMediaFile? = nil
    @Published var mediaPreviewFetched = false
    @Published var mediaVideoPlayReady = false
    @Published var mediaVideoPlaying = false
}
