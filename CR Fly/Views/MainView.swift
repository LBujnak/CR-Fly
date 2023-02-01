import SwiftUI

struct MainView: View {
    
    @State private var presentAlert = false
    
    @ObservedObject var globalData : GlobalData
    let djiService : ProductCommunicationService
    
    var body: some View {
        HStack(alignment: .top){
            VStack(alignment: .leading, spacing: 20) {
                Text("CR Fly Beta").font(.title).bold()
                Text("Connected to aircraft: " + (self.globalData.droneConnected ? "Yes": "No")).font(.title)
                Text("Connected to RC: " + (self.globalData.rcEngineConn ? "Yes": "No")).font(.title)
                Text("Bridge Mode Status: " + (self.globalData.enableBridgeMode ? "On" : "Off")).font(.title)
                if(self.globalData.sdkRegistered){
                    HStack(){
                        if(self.globalData.droneConnected){
                            Button("Lets FLY!"){
                                self.djiService.libController.stopPlaybackMode(completionHandler: {(error) in
                                    if(error != nil){
                                        createAlert(globalData: self.globalData, title: "Error", msg: "There was a problem opening fpv view: \(String(describing: error)).")
                                    }
                                    else{
                                        self.globalData.fpvMode = true
                                    }
                                })
                            }.buttonStyle(.bordered).font(.title2)
                            
                            Button("Photo Library"){
                                self.djiService.libController.startPlaybackMode(downloadPreview: true, completionHandler: {(error) in
                                    if(error != nil) {
                                        createAlert(globalData: self.globalData, title: "Error", msg: "There was a problem opening library: \(String(describing: error)).")
                                    }
                                    else{ self.globalData.libMode = true }
                                })
                            }.buttonStyle(.bordered).font(.title2)
                        }
                    }
                }
                Spacer()
            }
            VStack(alignment: .trailing, spacing: 20){
                if(self.globalData.sdkRegistered){
                    Button("Connect"){
                        self.djiService.connectToProduct()
                    }.buttonStyle(.bordered).font(.title3).disabled(self.globalData.droneConnected)
                    
                    Button("Connect"){
                    }.buttonStyle(.bordered).font(.title3).disabled(self.globalData.rcEngineConn)
                    
                    if(self.globalData.enableBridgeMode){
                        Button("Stop"){
                            self.djiService.stopBridgeMode()
                        }.buttonStyle(.bordered).font(.title3)
                    } else{
                        Button("Start"){
                            self.presentAlert = true
                        }.alert("Start", isPresented: self.$presentAlert, actions: {
                            TextField("IP Address", text: self.$globalData.bridgeAppIP)
                            Button("Start", action: {
                                self.globalData.enableBridgeMode = true
                                self.djiService.connectToProduct()
                            })
                            Button("Cancel", role: .cancel, action: {})
                        }, message: {
                            Text("Please enter IP Address of device running SDK Bridge App")
                        }).buttonStyle(.bordered).font(.title3)
                    }
                }
            }.padding([.top],50).padding([.horizontal],20)
            Spacer()
        }.padding([.top, .horizontal], 60).alert(isPresented: self.$globalData.globalAlert){ Alert(title: self.globalData.alertTitle, message: self.globalData.alertMsg, dismissButton: .cancel())
        }//.background(Color.black.ignoresSafeArea()).foregroundColor(.white)
    }
}

struct MainView_Previews: PreviewProvider {
    static let g = GlobalData()
    
    static var previews: some View {
        MainView(globalData: g, djiService: ProductCommunicationService(globalData: g))
    }
}

