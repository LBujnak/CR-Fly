import SwiftUI
import DJISDK

struct LibraryPreviewView: View {
    
    @ObservedObject var globalData : GlobalData
    let djiService : ProductCommunicationService
    
    var body: some View {
        VStack{
            ZStack{
                HStack{
                    if(self.globalData.mediaPreview != nil && self.isVideo(file: self.globalData.mediaPreview!)) {
                        VPView().background(Color.black.ignoresSafeArea()).ignoresSafeArea().opacity((self.globalData.mediaVideoPlayReady) ? 1 : 0)
                        
                    }
                    else if(self.globalData.mediaPreviewFetched){
                        Image(uiImage: self.globalData.mediaPreview!.preview!).resizable().scaledToFit()
                    }
                }
                VStack{
                    //TOP Bar
                    HStack(alignment: .top, spacing: 30){
                        Button("←"){
                            self.globalData.mediaPreviewFetched = false
                            self.globalData.mediaPreview = nil
                            
                            if(self.globalData.mediaVideoPlayReady) {
                                self.djiService.libController.stopVideo(completionHandler: {(error) in
                                    if(error != nil) { createAlert(globalData: self.globalData, title: "Error", msg: String(describing: "Error while stopping video: \(String(describing: error))"))
                                    }
                                })
                            }
                            
                            self.globalData.mediaVideoPlayReady = false
                            self.globalData.mediaVideoPlaying = false
                        }.foregroundColor(.white).font(.largeTitle)
                                        
                        Spacer()
                        Text("Low-Res Preview").bold().font(.caption).foregroundColor(.white).padding([.top],20)
                        if(self.globalData.mediaPreview != nil){
                            Text(self.globalData.mediaPreview!.timeCreated).foregroundColor(.white).padding([.top],15)
                        }
                        Spacer()
                        
                        Image(systemName: "square.and.arrow.up").font(.title2).padding([.top],10).foregroundColor(.white).onTapGesture {
                            createAlert(globalData: self.globalData, title: "In Develompent", msg: "This feature will be available in next version")
                        }
                        
                    }
                        
                    //Play,Pause buttons,Loading/
                    Spacer()
                    if(!self.globalData.mediaVideoPlayReady && !self.globalData.mediaPreviewFetched){
                        ProgressView().scaleEffect(x: 4, y: 4, anchor: .center).progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    
                    if(self.globalData.mediaVideoPlayReady) {
                        if(!self.globalData.mediaVideoPlaying && self.globalData.mediaVideoPlayReady){
                            Image(systemName: "play.circle.fill").font(.custom("PlayPause", size: 70)).foregroundColor(.white).onTapGesture {
                                    
                                self.djiService.libController.resumeVideo(completionHandler: {(error) in
                                    if(error != nil){
                                        createAlert(globalData: self.globalData, title: "Error", msg: "Error playing video: \(String(describing: error))")
                                    }
                                    self.globalData.mediaVideoPlaying = true
                                })
                            }
                        }
                        else if(self.globalData.mediaVideoPlaying){
                            Image(systemName: "pause.circle.fill").font(.custom("PlayPause", size: 70)).foregroundColor(.white).onTapGesture {
                                self.djiService.libController.pauseVideo(completionHandler: {(error) in
                                    if(error != nil){
                                        createAlert(globalData: self.globalData, title: "Error", msg: "Error resuming video: \(String(describing: error))")
                                    }
                                    self.globalData.mediaVideoPlaying = false
                                })
                            }
                        }
                    }
                    Spacer()
                    
                    //Bottom Bar
                    HStack{
                        Image(systemName: "trash").font(.title2).foregroundColor(.white).onTapGesture {
                            self.djiService.libController.removePreviewFile(completionHandler: {(error) in
                                if(error != nil) {
                                    createAlert(globalData: self.globalData, title: "Error", msg: "There was an error during removing selected files: \(String(describing: error))")
                                }
                                else{
                                    self.globalData.mediaPreview = nil
                                    self.globalData.mediaPreviewFetched = false
                                }
                            })
                        }
                        Spacer()
                        
                        //TODO: Slider na zmenu casu videa
                    }
                }
            }
        }.background(Color.black.ignoresSafeArea()).alert(isPresented: self.$globalData.globalAlert){ Alert(title: self.globalData.alertTitle, message: self.globalData.alertMsg, dismissButton: .cancel()) }
    }
    
    private func isVideo(file: DJIMediaFile) -> Bool{
        if(file.mediaType == DJIMediaType.MOV || file.mediaType == DJIMediaType.MP4) {
            return true
        } else { return false }
    }
}

struct LibraryPreviewView_Previews:
    PreviewProvider {
    
    static var previewData = GlobalData()
    
    static var previews: some View {
        LibraryPreviewView(globalData: previewData, djiService: ProductCommunicationService(globalData: previewData))
    }
}

struct VPView: UIViewControllerRepresentable{
    
    func makeUIViewController(context: Context) -> UIViewController{
        let storyboard = UIStoryboard(name: "VideoPlaybackView", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(identifier: "VideoPlaybackView")
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
