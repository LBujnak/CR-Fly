import SwiftUI

struct DroneFPVView: View {
    @ObservedObject var globalData : GlobalData
    
    var body: some View {
        ZStack{
            DefaultFPVLayoutStoryboard().edgesIgnoringSafeArea(.all)
            
            VStack{
                HStack{
                    Button("←"){
                        self.globalData.fpvMode = false
                    }.foregroundColor(.white).padding([.horizontal],-40).padding([.top],40).font(.largeTitle)
                    Spacer()
                }
                Spacer()
            }
        }.alert(isPresented: self.$globalData.globalAlert){ Alert(title: self.globalData.alertTitle, message: self.globalData.alertMsg, dismissButton: .cancel())}
    }
}

struct DroneFPVView_Previews: PreviewProvider {
    static var previews: some View {
        DroneFPVView(globalData: GlobalData())
    }
}

struct DefaultFPVLayoutStoryboard: UIViewControllerRepresentable{
    
    func makeUIViewController(context: Context) -> UIViewController{
        let storyboard = UIStoryboard(name: "DJIDefaultFPV", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(identifier: "DJIDefaultFPV")
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
