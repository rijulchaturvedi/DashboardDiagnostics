import SwiftUI

struct ResultView: View {
    let results: [ClassificationResult]
    let image: UIImage?
    let errorMessage: String?
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                if let top = results.first {
                    PrimaryResultCard(result: top)
                        .padding(.horizontal)
                        .padding(.top, 16)

                    if let msg = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                            Text(msg).font(.caption).foregroundColor(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    DetailCard(info: top.info)
                        .padding(.horizontal)
                        .padding(.top, 12)

                    if results.count > 1 {
                        OtherPredictions(results: Array(results.dropFirst()))
                            .padding(.horizontal)
                            .padding(.top, 16)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 48)).foregroundColor(.secondary)
                        Text("Could not identify symbol")
                            .font(.headline).foregroundColor(.secondary)
                        if let msg = errorMessage {
                            Text(msg).font(.caption).foregroundColor(.secondary)
                                .multilineTextAlignment(.center).padding(.horizontal, 32)
                        }
                        Text("Try a closer, well-lit photo of a single warning light.")
                            .font(.caption).foregroundColor(.secondary)
                            .multilineTextAlignment(.center).padding(.horizontal, 32)
                    }
                    .padding(.top, 40)
                }

                Button(action: onDismiss) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Scan Another")
                    }
                    .font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground))
    }
}

struct PrimaryResultCard: View {
    let result: ClassificationResult
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: result.source == .onDevice ? "cpu" : "cloud.fill")
                        .font(.system(size: 11))
                    Text(result.source.rawValue)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(result.source == .onDevice ? .secondary : .cyan)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color(.tertiarySystemBackground))
                .clipShape(Capsule())

                HStack(spacing: 4) {
                    Image(systemName: result.info.urgency.icon).font(.system(size: 12, weight: .semibold))
                    Text(result.info.urgency.rawValue.uppercased()).font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12).padding(.vertical, 4)
                .background(result.info.urgency.color)
                .clipShape(Capsule())
            }

            Text(result.info.displayName)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
            Text("\(Int(result.confidence * 100))% confidence")
                .font(.subheadline).foregroundColor(.secondary)
            Text(result.info.shortDescription)
                .font(.body).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct DetailCard: View {
    let info: WarningLightInfo
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "questionmark.circle").foregroundColor(.orange)
                    Text("What it means").font(.headline)
                }
                Text(info.whatItMeans).font(.body).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "wrench.and.screwdriver").foregroundColor(.blue)
                    Text("What to do").font(.headline)
                }
                Text(info.whatToDo).font(.body).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct OtherPredictions: View {
    let results: [ClassificationResult]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Other possibilities").font(.subheadline).foregroundColor(.secondary)
            ForEach(results) { result in
                HStack {
                    Circle().fill(result.info.symbolColor).frame(width: 10, height: 10)
                    Text(result.info.displayName).font(.subheadline)
                    Spacer()
                    Text("\(Int(result.confidence * 100))%").font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.vertical, 6).padding(.horizontal, 12)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
