import SwiftUI
import DJISDK
@main
struct AppController: App {
    
    @ObservedObject var globalData : GlobalData
    var djiService : ProductCommunicationService
    
    init() {
        let gData = GlobalData()
        self.djiService = ProductCommunicationService(globalData: gData)
        self.djiService.registerWithSDK()
        self.globalData = gData
    }
    
    var body: some Scene {
        WindowGroup {
            if(self.globalData.fpvMode){
                DroneFPVView(globalData: self.globalData)
            }
            else if(self.globalData.libMode){
                if(self.globalData.mediaLibPicked == nil){
                    LibraryView(globalData: self.globalData, djiService: self.djiService)
                }
                else {
                    LibraryPreviewView(globalData: globalData, djiService: self.djiService)
                }
            }
            else{
                MainView(globalData: self.globalData, djiService: self.djiService)
            }
        }
    }
}
