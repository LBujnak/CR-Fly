import DJISDK

class ProductCommunicationService: NSObject {
    
    private var globalData : GlobalData
    var libController : LibraryCommunicationService
    
    typealias CompletionHandler = (_ error : String?) -> Void
    
    init(globalData: GlobalData) {
        self.globalData = globalData
        self.libController = LibraryCommunicationService(globalData: globalData)
    }
    
    func registerWithSDK() {
        let appKey = Bundle.main.object(forInfoDictionaryKey: SDK_APP_KEY_INFO_PLIST_KEY) as? String
        
        guard appKey != nil && appKey!.isEmpty == false else {
            createAlert(globalData: self.globalData, title: "AppKey error", msg: "Please enter your app key in the info.plist")
            return
        }
        DJISDKManager.registerApp(with: self)
    }
    
    func connectToProduct(){
        DJISDKManager.stopConnectionToProduct()
        if (self.globalData.enableBridgeMode) {
            DJISDKManager.enableBridgeMode(withBridgeAppIP: self.globalData.bridgeAppIP)
            print("Bridge connection to " + self.globalData.bridgeAppIP + " has been started.")
        } else {
            if (DJISDKManager.startConnectionToProduct()) {
                print("Connection has been started.")
            } else {
                createAlert(globalData: self.globalData, title: "Connection error", msg: "There was a problem starting the connection.")
            }
        }
    }
    
    func stopBridgeMode(){
        self.globalData.droneConnected = false
        self.globalData.enableBridgeMode = false
        DJISDKManager.disableBridgeMode()
        print("Bridge connection to " + self.globalData.bridgeAppIP + " has been disabled.")
    }
    
}

extension ProductCommunicationService : DJISDKManagerDelegate {
    
    func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
        print("SDK downloading db file \(progress.completedUnitCount / progress.totalUnitCount)")
    }
    
    func appRegisteredWithError(_ error: Error?) {
        if (error != nil) {
            createAlert(globalData: self.globalData, title: "SDK Registered with error", msg: error?.localizedDescription ?? "")
            return
        }
        
        self.globalData.sdkRegistered = true
        self.connectToProduct()
    }
    
    func productConnected(_ product: DJIBaseProduct?) {
        print("Entered productConnected")
        guard let _ = product else {
            print("Product connected but was nil")
            createAlert(globalData: self.globalData, title: "Connection error", msg: "There was a problem connectiong to device.")
            return
        }
        self.globalData.droneConnected = true
    }
    
    func productDisconnected() {
        print("Entered productDisconnected")
        self.globalData.droneConnected = false
        self.globalData.mediaFetched = false
        self.globalData.mediaPreview = nil
        self.globalData.mediaSections = []
        //self.globalData.mediaList = []
        
        if(self.globalData.libMode) { self.globalData.libMode = false }
        if(self.globalData.fpvMode) { self.globalData.fpvMode = false }
    }
    
    func componentConnected(withKey key: String?, andIndex index: Int) {
        print("Entered componentConnected")
        if(!self.globalData.droneConnected && DJISDKManager.product() != nil && DJISDKManager.product()!.model != "Only RemoteController"){
            self.productConnected(DJISDKManager.product())
        }
    }
    
    func componentDisconnected(withKey key: String?, andIndex index: Int) {
        print("Entered componentDisonnected")
        if(self.globalData.droneConnected && (DJISDKManager.product() == nil || DJISDKManager.product()!.model == "Only RemoteController")){
            self.productDisconnected()
        }
    }
}
