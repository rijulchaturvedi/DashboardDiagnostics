import CoreML
import Vision
import UIKit

// MARK: - Data Models

enum ClassificationSource: String {
    case onDevice = "On-Device"
    case cloudAPI = "Cloud AI"
}

enum LLMProvider: String, CaseIterable, Identifiable {
    case claude = "Claude (Anthropic)"
    case gpt4o = "GPT-4o (OpenAI)"
    case gemini = "Gemini (Google)"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .claude: return "brain.head.profile"
        case .gpt4o: return "bubble.left.and.bubble.right"
        case .gemini: return "sparkles"
        }
    }

    var keyPlaceholder: String {
        switch self {
        case .claude: return "sk-ant-api03-..."
        case .gpt4o: return "sk-proj-..."
        case .gemini: return "AIzaSy..."
        }
    }

    var docsURL: String {
        switch self {
        case .claude: return "console.anthropic.com"
        case .gpt4o: return "platform.openai.com"
        case .gemini: return "aistudio.google.com"
        }
    }
}

struct ClassificationResult: Identifiable {
    let id = UUID()
    let classLabel: String
    let confidence: Float
    let info: WarningLightInfo
    let source: ClassificationSource
}

// MARK: - Classifier Service

class ClassifierService: ObservableObject {
    @Published var results: [ClassificationResult] = []
    @Published var isProcessing = false
    @Published var errorMessage: String?

    private var model: VNCoreMLModel?
    private let confidenceThreshold: Float = 0.70

    // Persisted via UserDefaults
    static var apiKey: String {
        get { UserDefaults.standard.string(forKey: "apiKey") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "apiKey") }
    }

    static var selectedProvider: LLMProvider {
        get {
            let raw = UserDefaults.standard.string(forKey: "llmProvider") ?? ""
            return LLMProvider(rawValue: raw) ?? .claude
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "llmProvider") }
    }

    static let classLabels: [String] = [
        "abs", "adaptive_cruise", "airbag", "auto_headlights", "auto_start_stop",
        "battery", "blind_spot", "brake", "check_engine", "cruise_control",
        "door_ajar", "dpf_warning", "esp", "fog_light", "frost_warning",
        "fuel", "glow_plug", "high_beam", "hill_assist", "hood_trunk_open",
        "key_warning", "lane_departure", "low_beam", "master_warning", "oil_pressure",
        "parking_brake", "power_steering", "rear_fog", "seatbelt", "service_engine",
        "temperature", "tire_pressure", "traction_control", "transmission",
        "turn_signal", "washer_fluid"
    ]

    init() { loadModel() }

    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            let mlModel = try DashboardClassifier(configuration: config).model
            model = try VNCoreMLModel(for: mlModel)
        } catch {
            errorMessage = "Failed to load model: \(error.localizedDescription)"
        }
    }

    func classify(image: UIImage) {
        guard let cgImage = image.cgImage else {
            errorMessage = "Invalid image"
            return
        }

        isProcessing = true
        errorMessage = nil

        classifyOnDevice(cgImage: cgImage) { [weak self] onDeviceResults in
            guard let self = self else { return }
            let topConf = onDeviceResults.first?.confidence ?? 0
            let hasKey = !Self.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            if topConf < self.confidenceThreshold && hasKey {
                // Try cloud fallback
                print("[ClassifierService] On-device confidence \(topConf) < \(self.confidenceThreshold), trying \(Self.selectedProvider.rawValue) fallback...")
                self.classifyWithCloudAPI(image: image) { cloudResults in
                    DispatchQueue.main.async {
                        if let cloudResults = cloudResults, !cloudResults.isEmpty {
                            print("[ClassifierService] Cloud returned: \(cloudResults.first?.classLabel ?? "nil") at \(cloudResults.first?.confidence ?? 0)")
                            self.results = cloudResults
                        } else {
                            print("[ClassifierService] Cloud fallback failed, showing on-device result")
                            self.results = onDeviceResults
                            self.errorMessage = "\(Self.selectedProvider.rawValue) fallback failed. Showing on-device result."
                        }
                        self.isProcessing = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.results = onDeviceResults
                    self.isProcessing = false
                    if topConf < self.confidenceThreshold && !hasKey {
                        self.errorMessage = "Low confidence (\(Int(topConf * 100))%). Add API key in Settings for better results."
                    }
                }
            }
        }
    }

    // MARK: - On-Device

    private func classifyOnDevice(cgImage: CGImage, completion: @escaping ([ClassificationResult]) -> Void) {
        guard let model = model else { completion([]); return }

        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            if error != nil { completion([]); return }
            let results = self?.processVisionResults(request.results) ?? []
            completion(results)
        }
        request.imageCropAndScaleOption = .centerCrop

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    private func processVisionResults(_ vnResults: [Any]?) -> [ClassificationResult] {
        if let observations = vnResults as? [VNCoreMLFeatureValueObservation],
           let firstResult = observations.first,
           let multiArray = firstResult.featureValue.multiArrayValue {

            var logits: [Float] = []
            for i in 0..<multiArray.count {
                logits.append(Float(truncating: multiArray[i]))
            }

            let probs = softmax(logits)
            let indexed = probs.enumerated().sorted { $0.element > $1.element }

            return indexed.prefix(3).compactMap { (index, confidence) in
                guard index < Self.classLabels.count else { return nil }
                let label = Self.classLabels[index]
                return ClassificationResult(
                    classLabel: label, confidence: confidence,
                    info: WarningLightInfo.lookup(label), source: .onDevice
                )
            }
        }

        if let classifications = vnResults as? [VNClassificationObservation] {
            return classifications.prefix(3).map { obs in
                ClassificationResult(
                    classLabel: obs.identifier, confidence: obs.confidence,
                    info: WarningLightInfo.lookup(obs.identifier), source: .onDevice
                )
            }
        }
        return []
    }

    // MARK: - Cloud API Fallback

    private func classifyWithCloudAPI(image: UIImage, completion: @escaping ([ClassificationResult]?) -> Void) {
        guard let resized = resizeImage(image, maxDimension: 512),
              let jpegData = resized.jpegData(compressionQuality: 0.8) else {
            print("[ClassifierService] Failed to resize/encode image")
            completion(nil); return
        }

        let base64 = jpegData.base64EncodedString()
        let labelsStr = Self.classLabels.joined(separator: ", ")
        let prompt = "This is a photo of a car dashboard warning light symbol. Identify which symbol it is. Reply ONLY with a JSON object, nothing else: {\"label\": \"<label>\", \"confidence\": <0.0-1.0>}. Choose label from: \(labelsStr). If unsure, pick the closest match."

        print("[ClassifierService] Calling \(Self.selectedProvider.rawValue) with \(base64.count) chars of base64")

        switch Self.selectedProvider {
        case .claude:  callClaude(base64: base64, prompt: prompt, completion: completion)
        case .gpt4o:   callGPT4o(base64: base64, prompt: prompt, completion: completion)
        case .gemini:  callGemini(base64: base64, prompt: prompt, completion: completion)
        }
    }

    // MARK: Claude

    private func callClaude(base64: String, prompt: String, completion: @escaping ([ClassificationResult]?) -> Void) {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { completion(nil); return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Self.apiKey.trimmingCharacters(in: .whitespacesAndNewlines), forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.timeoutInterval = 20

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 100,
            "messages": [["role": "user", "content": [
                ["type": "image", "source": ["type": "base64", "media_type": "image/jpeg", "data": base64]],
                ["type": "text", "text": prompt]
            ]]]
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            if let error = error {
                print("[Claude] Network error: \(error.localizedDescription)")
                completion(nil); return
            }
            let httpResponse = response as? HTTPURLResponse
            print("[Claude] HTTP \(httpResponse?.statusCode ?? 0)")

            guard let data = data else { completion(nil); return }

            if let raw = String(data: data, encoding: .utf8) {
                print("[Claude] Response: \(raw.prefix(300))")
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]],
                  let text = content.first?["text"] as? String else {
                print("[Claude] Failed to parse response")
                completion(nil); return
            }
            completion(self?.parseAPIResponse(text))
        }.resume()
    }

    // MARK: GPT-4o

    private func callGPT4o(base64: String, prompt: String, completion: @escaping ([ClassificationResult]?) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { completion(nil); return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(Self.apiKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 20

        let body: [String: Any] = [
            "model": "gpt-4o",
            "max_tokens": 100,
            "messages": [["role": "user", "content": [
                ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64)"]],
                ["type": "text", "text": prompt]
            ]]]
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            if let error = error {
                print("[GPT-4o] Network error: \(error.localizedDescription)")
                completion(nil); return
            }
            let httpResponse = response as? HTTPURLResponse
            print("[GPT-4o] HTTP \(httpResponse?.statusCode ?? 0)")

            guard let data = data else { completion(nil); return }

            if let raw = String(data: data, encoding: .utf8) {
                print("[GPT-4o] Response: \(raw.prefix(300))")
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let text = message["content"] as? String else {
                print("[GPT-4o] Failed to parse response")
                completion(nil); return
            }
            completion(self?.parseAPIResponse(text))
        }.resume()
    }

    // MARK: Gemini

    private func callGemini(base64: String, prompt: String, completion: @escaping ([ClassificationResult]?) -> Void) {
        let key = Self.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        // Use header-based auth to avoid URL encoding issues with API keys
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent") else {
            print("[Gemini] Invalid URL")
            completion(nil); return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(key, forHTTPHeaderField: "x-goog-api-key")
        req.timeoutInterval = 20

        let body: [String: Any] = [
            "contents": [["parts": [
                ["inline_data": ["mime_type": "image/jpeg", "data": base64]],
                ["text": prompt]
            ]]]
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            if let error = error {
                print("[Gemini] Network error: \(error.localizedDescription)")
                completion(nil); return
            }
            let httpResponse = response as? HTTPURLResponse
            print("[Gemini] HTTP \(httpResponse?.statusCode ?? 0)")

            guard let data = data else { completion(nil); return }

            if let raw = String(data: data, encoding: .utf8) {
                print("[Gemini] Response: \(raw.prefix(500))")
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]] else {
                // Check for error response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any] {
                    print("[Gemini] API Error: \(error["message"] ?? "unknown")")
                }
                print("[Gemini] Failed to parse response")
                completion(nil); return
            }
            // Find the first part that has text (skip thinking parts)
            let text = parts.compactMap { $0["text"] as? String }.first(where: { !$0.isEmpty })
            guard let text = text else {
                print("[Gemini] No text in parts")
                completion(nil); return
            }
            completion(self?.parseAPIResponse(text))
        }.resume()
    }

    // MARK: - Helpers

    private func parseAPIResponse(_ text: String) -> [ClassificationResult]? {
        print("[ClassifierService] Parsing API text: \(text)")

        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let label = json["label"] as? String else {
            print("[ClassifierService] JSON parse failed for: \(cleaned)")
            return nil
        }

        // Accept the label even if not in our exact list (close match)
        let finalLabel = Self.classLabels.contains(label) ? label : Self.classLabels.first { $0.contains(label) || label.contains($0) } ?? label
        let conf = (json["confidence"] as? NSNumber)?.floatValue ?? 0.85

        return [ClassificationResult(
            classLabel: finalLabel, confidence: conf,
            info: WarningLightInfo.lookup(finalLabel), source: .cloudAPI
        )]
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

    private func softmax(_ logits: [Float]) -> [Float] {
        let maxLogit = logits.max() ?? 0
        let exps = logits.map { exp($0 - maxLogit) }
        let sumExps = exps.reduce(0, +)
        return exps.map { $0 / sumExps }
    }
}
