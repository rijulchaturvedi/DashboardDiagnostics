import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var classifier = ClassifierService()

    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showResults = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                if showResults, capturedImage != nil {
                    ResultView(
                        results: classifier.results,
                        image: capturedImage,
                        errorMessage: classifier.errorMessage,
                        onDismiss: { reset() }
                    )
                } else {
                    homeView
                }
            }
            .navigationTitle(showResults ? "Result" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showResults {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") { reset() }
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(capturedImage: $capturedImage, isPresented: $showCamera)
                .ignoresSafeArea()
                .onDisappear { processImageIfNeeded() }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .onChange(of: selectedPhotoItem) { newItem in
            loadFromPhotoPicker(newItem)
        }
    }

    private var homeView: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                    Image(systemName: "car.fill")
                        .font(.system(size: 42))
                        .foregroundColor(.white)
                }
                Text("Dashboard Diagnostics")
                    .font(.system(size: 28, weight: .bold))
                Text("Point your camera at a dashboard warning\nlight to identify it instantly.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()

            VStack(spacing: 12) {
                Button(action: { showCamera = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill").font(.system(size: 18))
                        Text("Take Photo").font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle").font(.system(size: 18))
                        Text("Choose from Library").font(.headline)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            HStack(spacing: 4) {
                Image(systemName: "cpu").font(.caption)
                Text("36 symbols · On-device ML · Tap ⚙ for settings")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            .padding(.bottom, 24)
        }
        .overlay {
            if classifier.isProcessing {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView().scaleEffect(1.5).tint(.white)
                        Text("Analyzing...").font(.headline).foregroundColor(.white)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
        }
    }

    private func processImageIfNeeded() {
        guard let image = capturedImage else { return }
        classifier.classify(image: image)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showResults = true }
    }

    private func loadFromPhotoPicker(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                if case .success(let data) = result, let data = data,
                   let image = UIImage(data: data) {
                    capturedImage = image
                    classifier.classify(image: image)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showResults = true }
                }
                selectedPhotoItem = nil
            }
        }
    }

    private func reset() {
        showResults = false
        capturedImage = nil
        classifier.results = []
        classifier.errorMessage = nil
    }
}

// MARK: - Settings

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKeyInput: String = ClassifierService.apiKey
    @State private var selectedProvider: LLMProvider = ClassifierService.selectedProvider
    @State private var showKey = false

    var body: some View {
        NavigationStack {
            Form {
                // Provider picker
                Section(header: Text("Cloud AI Provider")) {
                    ForEach(LLMProvider.allCases) { provider in
                        Button {
                            selectedProvider = provider
                            // Clear key when switching providers
                            if ClassifierService.selectedProvider != provider {
                                apiKeyInput = ""
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: provider.iconName)
                                    .font(.system(size: 16))
                                    .frame(width: 28)
                                    .foregroundColor(selectedProvider == provider ? .blue : .secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(provider.rawValue)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text(provider.docsURL)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if selectedProvider == provider {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                // API key
                Section(
                    header: Text("\(selectedProvider.rawValue) API Key"),
                    footer: Text("When on-device confidence is below 70%, the image is sent to \(selectedProvider.rawValue) for a second opinion. Key is stored locally only.")
                        .font(.caption)
                ) {
                    HStack {
                        if showKey {
                            TextField(selectedProvider.keyPlaceholder, text: $apiKeyInput)
                                .font(.system(.body, design: .monospaced))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField(selectedProvider.keyPlaceholder, text: $apiKeyInput)
                                .font(.system(.body, design: .monospaced))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        Button { showKey.toggle() } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                    if !apiKeyInput.isEmpty {
                        Button("Clear Key", role: .destructive) { apiKeyInput = "" }
                    }
                }

                // Status
                Section(header: Text("Current Mode")) {
                    HStack {
                        Image(systemName: apiKeyInput.isEmpty ? "cpu" : "bolt.horizontal")
                            .foregroundColor(apiKeyInput.isEmpty ? .secondary : .green)
                        Text(apiKeyInput.isEmpty ? "On-device only" : "Hybrid: On-device + \(selectedProvider.rawValue)")
                            .font(.subheadline)
                    }
                }

                // About
                Section(header: Text("About")) {
                    LabeledContent("On-device model", value: "MobileNetV2 (36 classes)")
                    LabeledContent("Confidence threshold", value: "70%")
                    LabeledContent("Cloud fallback", value: selectedProvider.rawValue)
                }

                // Developer
                Section {
                    VStack(spacing: 4) {
                        Text("Designed & Developed by")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Rijul Chaturvedi")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        ClassifierService.apiKey = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        ClassifierService.selectedProvider = selectedProvider
                        dismiss()
                    }
                }
            }
        }
    }
}
