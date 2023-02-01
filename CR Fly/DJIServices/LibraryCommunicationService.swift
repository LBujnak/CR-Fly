import Foundation
import SwiftUI
import DJISDK

class LibraryCommunicationService : NSObject{
    
    private var globalData : GlobalData
    private var drone : DJIBaseProduct? = nil
    private var camera : DJICamera? = nil
    init(globalData: GlobalData) { self.globalData = globalData }
    
    private func refreshDroneAndCamera() -> String? {
        self.drone = DJISDKManager.product()
        if(self.drone == nil){ return "Product is connected, but DJISDKManager.product() is nil" }
        
        self.camera = drone!.camera
        if(self.camera == nil){ return "Unable to detect camera" }
        
        if(!camera!.isMediaDownloadModeSupported()){ return "Product does not support media download mode" }
        return nil
    }
    
    func startPlaybackMode(downloadPreview: Bool, completionHandler: @escaping (String?) -> Void){
        
        let mainError : String? = self.refreshDroneAndCamera()
    
        if(mainError != nil){ completionHandler(mainError) }
        else{
            self.camera!.enterPlayback(completion: {(error) in
                if (error != nil) { completionHandler(error!.localizedDescription) }
            })
            
            if(mainError != nil){ completionHandler(mainError) }
            else{
                let manager = camera!.mediaManager!
                manager.refreshFileList(of: DJICameraStorageLocation.sdCard, withCompletion: { (error) in
                    if(error != nil){ completionHandler("refresh error state: \(manager.sdCardFileListState.rawValue)") }
                    else {
                        let files : [DJIMediaFile] = manager.sdCardFileListSnapshot() ?? []
                        
                        if(!self.globalData.mediaList.elementsEqual(files)){
                            self.globalData.mediaList.removeAll()
                            self.globalData.mediaSections.removeAll()
                            self.globalData.mediaPreviewFetched = false
                            
                            
                            var sections = 0
                            for i in 0..<files.count{
                                if(self.globalData.mediaList.last?.timeCreated.prefix(10) != files[i].timeCreated.prefix(10)){
                                    var newSection : [DJIMediaFile] = []
                                    newSection.append(files[i])
                                    
                                    self.globalData.mediaSections.append(newSection)
                                    sections += 1
                                }
                                self.globalData.mediaList.append(files[i])
                                self.globalData.mediaSections[sections-1].append(files[i])
                            }
                            
                            if(self.globalData.mediaList.count > 0 && downloadPreview){
                                self.downloadThumbnail(index: 0, retries: 0)
                            }
                        }
                        completionHandler(nil)
                    }
                })
            }
        }
    }
    
    func stopPlaybackMode(completionHandler: @escaping (String?) -> Void){
        
        let mainError : String? = self.refreshDroneAndCamera()
        
        if(mainError != nil){ completionHandler(mainError) }
        else{
            self.camera!.exitPlayback(completion: {(error) in
                if (error != nil) { completionHandler("While exiting playbackMode catched error: \(error!.localizedDescription)") }
                else { completionHandler(nil) }
            })
        }
    }
    
    private func downloadThumbnail(index: Int, retries: Int){
        if(index >= self.globalData.mediaList.count){
            self.globalData.mediaFetched = true
        }
        else{
            self.globalData.mediaList[index].fetchThumbnail(completion: { (error) in
                if(error != nil ) {
                    print("dwnld error: \(String(describing: error))")
                    if(retries < 5){
                        sleep(2)
                        self.downloadThumbnail(index: index, retries: retries+1)
                    } else {
                        createAlert(globalData: self.globalData, title: "Downloading thumbnail image error", msg: "Error message: \(String(describing: error)).")
                        self.globalData.mediaFetched = false
                        self.globalData.mediaList = []
                    }
                }
                else {
                    if(self.globalData.libMode) {
                        self.downloadThumbnail(index: self.globalData.mediaList.index(after: index), retries: retries)
                    }
                }
            })
        }
    }
    
    func removeFiles(files : Set<DJIMediaFile>, completionHandler : @escaping (String?) -> Void){
        var mainError : String? = self.refreshDroneAndCamera()
        var remFileList : [DJIMediaFile] = []
        
        if(mainError != nil){ completionHandler(mainError) }
        else{
            for file in files{ remFileList.append(file) }
            
            self.camera!.mediaManager?.delete(remFileList, withCompletion: {(failedFiles, error) in
                if(error != nil || failedFiles.count != 0){
                    mainError = "Error during deleting files, details: \(String(describing: error))"
                    completionHandler(mainError)
                }
                
                self.startPlaybackMode(downloadPreview: false, completionHandler: {(error) in
                    if(error != nil){ completionHandler("Error while reloading photos: \(String(describing: error))") }
                    else{ completionHandler(nil) }
                })
            })
        }
    }
    
    func removePreviewFile(completionHandler : @escaping (String?) -> Void){
        let mainError : String? = self.refreshDroneAndCamera()
        var files : Set<DJIMediaFile> = []
        
        if(mainError != nil){ completionHandler(mainError) }
        else{
            if(self.globalData.mediaPreview != nil) {
                files.insert(self.globalData.mediaPreview!)
            }
            
            self.removeFiles(files: files, completionHandler: {(error) in
                if(error != nil) { completionHandler(error) }
                else { completionHandler(nil) }
            })
        }
    }
    
    func playVideo(videoMedia: DJIMediaFile, completionHandler : @escaping (String?) -> Void){
        var mainError : String? = self.refreshDroneAndCamera()
        
        if(mainError != nil){ completionHandler(mainError) }
        else{
            self.camera!.mediaManager!.playVideo(videoMedia, withCompletion: {(error) in
                if(error != nil) {
                    mainError = String(describing: error!)
                    completionHandler(mainError)
                }
                else { completionHandler(nil) }
            })
        }
    }
    func pauseVideo(completionHandler : @escaping (String?) -> Void){
        let mainError : String? = self.refreshDroneAndCamera()
        if(mainError != nil){ completionHandler(mainError) }
        else{
            self.camera!.mediaManager!.pause(completion: {(error) in
                if(error != nil){ completionHandler(String(describing: error)) }
                else{ completionHandler(nil) }
            })
        }
    }
    func resumeVideo(completionHandler : @escaping (String?) -> Void){
        let mainError : String? = self.refreshDroneAndCamera()
        if(mainError != nil){ completionHandler(mainError) }
        else{
            self.camera!.mediaManager!.resume(completion: {(error) in
                if(error != nil){ completionHandler(String(describing: error)) }
                else{ completionHandler(nil) }
            })
        }
    }
    func stopVideo(completionHandler : @escaping (String?) -> Void){
        let mainError : String? = self.refreshDroneAndCamera()
        
        if(mainError != nil){ completionHandler(mainError) }
        else{
            self.camera!.mediaManager!.stop(completion: {(error) in
                if(error != nil){ completionHandler(String(describing: error)) }
                else{ completionHandler(nil) }
            })
        }
    }
    
    func changeVideoPreviewTime(time : Float, completionHandler : @escaping (String?) -> Void){
        let mainError : String? = self.refreshDroneAndCamera()
        
        if(mainError != nil){ completionHandler(mainError) }
        else{
            self.camera!.mediaManager!.move(toPosition: time, withCompletion: {(error) in
                if(error != nil){ completionHandler(String(describing: error)) }
                else{ completionHandler(nil) }
            })
        }
    }
    
    func prepareVideoPreview(file : DJIMediaFile){
        self.playVideo(videoMedia: file){ (error) in
            if(error != nil){
                createAlert(globalData: self.globalData, title: "Error", msg: "Error preparing video:  \(String(describing: error))")
            }
            else{
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    self.pauseVideo(){ (error) in
                        if(error != nil){
                            createAlert(globalData: self.globalData, title: "Error", msg: "Error preparing video:  \(String(describing: error))")
                        }
                        else{
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                                self.globalData.mediaVideoPlayReady = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    func fetchPreviewFor(file: DJIMediaFile){
        file.fetchPreview(completion: {(error) in
            if(error != nil){
                self.globalData.mediaPreview = nil
                createAlert(globalData: self.globalData, title: "Error", msg: "Error opening preview: \(String(describing: error))")
            }
            else{
                self.globalData.mediaPreviewFetched = true
            }
        })
    }
}
