import Foundation
import SwiftUI

func createAlert(globalData : GlobalData, title : String, msg : String){
    globalData.alertTitle = Text(title)
    globalData.alertMsg = Text(msg)
    globalData.globalAlert = true
}

