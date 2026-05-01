import SwiftUI
import Photos
import PhotosUI
import MapKit

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedAsset: PHAsset?
    @State private var position: MapCameraPosition = .automatic
    @State private var targetCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917)
    @State private var latInput: String = "35.6895"
    @State private var lonInput: String = "139.7454"
    @State private var isProcessing = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部地图选点区
                ZStack {
                    Map(initialPosition: position) {
                        Marker("目标位置", coordinate: targetCoordinate)
                    }
                    .onMapCameraChange { context in
                        targetCoordinate = context.camera.centerCoordinate
                        latInput = String(format: "%.6f", targetCoordinate.latitude)
                        lonInput = String(format: "%.6f", targetCoordinate.longitude)
                    }
                    
                    Circle()
                        .fill(.blue.opacity(0.2))
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding()

                // 控制面板
                Form {
                    Section("坐标精准输入") {
                        HStack {
                            Text("纬度:")
                            TextField("Latitude", text: $latInput)
                                .keyboardType(.decimalPad)
                                .onChange(of: latInput) { syncCoordinate() }
                        }
                        HStack {
                            Text("经度:")
                            TextField("Longitude", text: $lonInput)
                                .keyboardType(.decimalPad)
                                .onChange(of: lonInput) { syncCoordinate() }
                        }
                    }

                    Section("照片选择") {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Label(selectedItem == nil ? "点击选择照片" : "已选择 1 张照片", systemImage: "photo.on.rectangle")
                        }
                    }

                    Section {
                        Button(action: executeLocationUpdate) {
                            if isProcessing {
                                ProgressView().progressViewStyle(.circular)
                            } else {
                                Text("写入 GPS 数据")
                                    .frame(maxWidth: .infinity)
                                    .bold()
                            }
                        }
                        .disabled(selectedItem == nil || isProcessing)
                        .listRowBackground(selectedItem == nil ? Color.gray.opacity(0.1) : Color.blue)
                        .foregroundColor(.white)
                    }
                }
            }
            .navigationTitle("GeoModifier Pro")
            .alert("执行结果", isPresented: $showAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func syncCoordinate() {
        if let lat = Double(latInput), let lon = Double(lonInput) {
            targetCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }

    private func executeLocationUpdate() {
        guard let item = selectedItem else { return }
        isProcessing = true
        
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            guard status == .authorized || status == .limited else {
                handleResult(success: false, error: "无相册读写权限")
                return
            }
            
            let identifier = item.itemIdentifier!
            let assetResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            
            guard let asset = assetResult.firstObject else {
                handleResult(success: false, error: "无法加载资源句柄")
                return
            }

            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest(for: asset)
                request.location = CLLocation(
                    latitude: targetCoordinate.latitude,
                    longitude: targetCoordinate.longitude
                )
            }) { success, error in
                handleResult(success: success, error: error?.localizedDescription)
            }
        }
    }

    private func handleResult(success: Bool, error: String?) {
        DispatchQueue.main.async {
            self.isProcessing = false
            self.alertMessage = success ? "GPS 坐标已覆盖至：\n\(latInput), \(lonInput)" : "写入失败: \(error ?? "未知错误")"
            self.showAlert = true
        }
    }
}
