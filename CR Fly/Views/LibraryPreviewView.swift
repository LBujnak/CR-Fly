import SwiftUI
import DJISDK

struct LibraryPreviewView: View {
    
    @ObservedObject var globalData : GlobalData
    let djiService : ProductCommunicationService
    
    @State var showingMediaControls : Bool = true
    
    var body: some View {
        VStack{
            if(self.globalData.mediaLibPicked != nil){
                ZStack{
                    HStack{
                        if(self.globalData.mediaLibPicked != nil && self.isVideo(file: self.globalData.mediaLibPicked!)) {
                            VPView().background(Color.black.ignoresSafeArea()).ignoresSafeArea().opacity((self.globalData.mediaPreviewReady) ? 1 : 0)
                            
                        }
                        else if(self.globalData.mediaPreviewReady){
                            Image(uiImage: self.globalData.mediaLibPicked!.preview!).resizable().scaledToFit()
                        }
                    }
                    VStack{
                        if(self.showingMediaControls) { self.createTopBar() }
                        
                        //Play,Pause buttons,Loading
                        Spacer()
                        if(!self.globalData.mediaPreviewReady){
                            ProgressView().scaleEffect(x: 4, y: 4, anchor: .center).progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        
                        if(self.isVideo(file: self.globalData.mediaLibPicked) && self.globalData.mediaPreviewReady) {
                            if(!self.globalData.mediaPreviewVideoPlaying && self.globalData.mediaPreviewReady){
                                Image(systemName: "play.circle.fill").font(.custom("PlayPause", size: 70)).foregroundColor(.white).onTapGesture {
                                    self.djiService.libController.resumeVideo(completionHandler: {(error) in
                                        if(error != nil){
                                            createAlert(globalData: self.globalData, title: "Error", msg: "Error resuming video: \( error!)")
                                            return
                                        }
                                        self.globalData.mediaPreviewVideoPlaying = true
                                        self.showingMediaControls = false
                                    })
                                }
                            }
                            else if(self.globalData.mediaPreviewVideoPlaying && self.showingMediaControls){
                                Image(systemName: "pause.circle.fill").font(.custom("PlayPause", size: 70)).foregroundColor(.white).onTapGesture {
                                    self.djiService.libController.pauseVideo(completionHandler: {(error) in
                                        if(error != nil){
                                            createAlert(globalData: self.globalData, title: "Error", msg: "Error resuming video: \(error!)")
                                            return
                                        }
                                        self.globalData.mediaPreviewVideoPlaying = false
                                    })
                                }
                            }
                        }
                        Spacer()
                        
                        if(self.showingMediaControls) { self.createBottomBar() }
                    }
                }
            }
        }.background(Color.black.ignoresSafeArea()).alert(isPresented: self.$globalData.globalAlert ){ Alert(title: self.globalData.alertTitle, message: self.globalData.alertMsg, dismissButton: .cancel()) }
            .onTapGesture { self.showingMediaControls.toggle() }
    }
    
    private func createTopBar() -> some View{
        HStack(alignment: .top, spacing: 30){
            Button("←"){
                if(self.isVideo(file: self.globalData.mediaLibPicked!)) {
                    self.djiService.libController.stopVideo(completionHandler: {(error) in
                        if(error != nil) { createAlert(globalData: self.globalData, title: "Error", msg: "Error while stopping video: \(error!)")
                        }
                    })
                }
                
                self.globalData.mediaPreviewVideoPlaying = false
                self.globalData.mediaPreviewVideoCTime = 0
                self.globalData.mediaPreviewReady = false
                self.globalData.mediaLibPicked = nil
            }.foregroundColor(.white).font(.largeTitle)
                            
            Spacer()
            Text("Low-Res Preview").bold().font(.caption).foregroundColor(.white).padding([.top],20)
            if(self.globalData.mediaLibPicked != nil){
                Text(self.globalData.mediaLibPicked!.timeCreated).foregroundColor(.white).padding([.top],15)
            }
            Spacer()
            
            Image(systemName: "square.and.arrow.up").font(.title2).padding([.top],10).foregroundColor(.white).onTapGesture {
                createAlert(globalData: self.globalData, title: "In Develompent", msg: "This feature will be available in next version")
            }
        }
    }
    
    private func createBottomBar() -> some View{
        HStack{
            Image(systemName: "trash").font(.title2).foregroundColor(.white).onTapGesture {
                self.djiService.libController.removePreviewFile(completionHandler: {(error) in
                    if(error != nil) {
                        createAlert(globalData: self.globalData, title: "Error", msg: "There was an error during removing selected files: \(error!)")
                    }
                    else{
                        self.globalData.mediaLibPicked = nil
                        self.globalData.mediaPreviewReady = false
                    }
                })
            }
            Spacer()
            
            if(self.isVideo(file: self.globalData.mediaLibPicked!)){
                let totalTime : Double = Double(Int(globalData.mediaLibPicked!.durationInSeconds))
                
                let elapsedTime = Binding(
                    get: { Double(self.globalData.mediaPreviewVideoCTime) },
                    set: { self.globalData.mediaPreviewVideoCTime = Int($0) }
                )
                HStack{
                    let elapsed = secondsToVideoTime(seconds: self.globalData.mediaPreviewVideoCTime)
                    let total = secondsToVideoTime(seconds: Int(self.globalData.mediaLibPicked!.durationInSeconds))
                    
                    if(totalTime >= 3600){ Text(String(format: "%.2i:%.2i:%.2i",elapsed.hours,elapsed.minutes,elapsed.seconds)).foregroundColor(.white) }
                    else { Text(String(format: "%.2i:%.2i",elapsed.minutes,elapsed.seconds)).foregroundColor(.white) }
                    
                    Slider(value: elapsedTime, in: 0...totalTime ,onEditingChanged: {(chg) in
                        self.globalData.mediaPreviewVideoChanging = chg
                        if(!chg) {
                            self.djiService.libController.changeVideoPreviewTime(time: Float(self.globalData.mediaPreviewVideoCTime), completionHandler: {(error) in
                                if(error != nil){
                                    createAlert(globalData: self.globalData, title: "Error", msg: "There was an error during changing preview time: \(error!)")
                                }
                            })
                        }
                    }).tint(.white).onAppear(){
                        let thumbImage = ImageRenderer(content: bullThumb).uiImage ?? UIImage()
                        UISlider.appearance().setThumbImage(thumbImage, for: .normal)
                    }
                    
                    if(totalTime >= 3600){ Text(String(format: "%.2i:%.2i:%.2i",total.hours,total.minutes,total.seconds)).foregroundColor(.white) }
                    else { Text(String(format: "%.2i:%.2i",total.minutes,total.seconds)).foregroundColor(.white) }
                }.frame(width: 400)
            }
            Spacer()
        }
    }
    
    private func secondsToVideoTime(seconds : Int) -> videoTime{
        let hours = seconds/3600
        let minutes = (seconds - hours*3600)/60
        let sec = (seconds - hours*3600 - minutes*60)
        return videoTime(seconds: sec, minutes: minutes, hours: hours)
    }
    
    private func isVideo(file: DJIMediaFile?) -> Bool{
        if(file == nil) { return false }
        else if(file!.mediaType == DJIMediaType.MOV || file!.mediaType == DJIMediaType.MP4) {
            return true
        } else { return false }
    }
    
    var bullThumb: some View {
        //VStack {
            ZStack {
                Circle()
                    .frame(width: 25, height: 25)
                    .foregroundColor(.white)
            }.foregroundColor(.blue)
        //}.frame(width: 50, height: 60)
    }
    
    class videoTime{
        let seconds : Int
        let minutes : Int
        let hours : Int
        
        init(seconds: Int, minutes: Int, hours: Int) {
            self.seconds = seconds
            self.minutes = minutes
            self.hours = hours
        }
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
