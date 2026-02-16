import SwiftUI
import AVFoundation
import UIKit

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func didCapture(image: UIImage) {
            parent.capturedImage = image
            parent.isPresented = false
        }

        func didCancel() {
            parent.isPresented = false
        }
    }
}

protocol CameraViewControllerDelegate: AnyObject {
    func didCapture(image: UIImage)
    func didCancel()
}

class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?

    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!

    private let shutterButton = UIButton()
    private let closeButton = UIButton()
    private let guideLabel = UILabel()
    private let guideSquare = UIView()
    private let dimOverlay = UIView()

    private let guideSize: CGFloat = 240
    private let guideYOffset: CGFloat = -40

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        updateDimOverlay()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }

    // MARK: - Camera

    private func setupCamera() {
        session.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            showError("Camera not available")
            return
        }
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapToFocus(_:))))
    }

    // MARK: - Dim overlay

    private func updateDimOverlay() {
        dimOverlay.frame = view.bounds
        let centerX = view.bounds.midX
        let centerY = view.bounds.midY + guideYOffset
        let cutout = CGRect(x: centerX - guideSize/2, y: centerY - guideSize/2, width: guideSize, height: guideSize)

        let path = UIBezierPath(rect: view.bounds)
        path.append(UIBezierPath(roundedRect: cutout, cornerRadius: 16))
        path.usesEvenOddFillRule = true

        let mask = CAShapeLayer()
        mask.path = path.cgPath
        mask.fillRule = .evenOdd
        dimOverlay.layer.mask = mask
    }

    // MARK: - UI

    private func setupUI() {
        dimOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        dimOverlay.isUserInteractionEnabled = false
        view.addSubview(dimOverlay)

        guideSquare.translatesAutoresizingMaskIntoConstraints = false
        guideSquare.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        guideSquare.layer.borderWidth = 2.5
        guideSquare.layer.cornerRadius = 16
        guideSquare.isUserInteractionEnabled = false
        view.addSubview(guideSquare)
        addCornerAccents(to: guideSquare)

        shutterButton.translatesAutoresizingMaskIntoConstraints = false
        shutterButton.backgroundColor = .white
        shutterButton.layer.cornerRadius = 36
        shutterButton.layer.borderWidth = 4
        shutterButton.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        shutterButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(shutterButton)

        let inner = UIView()
        inner.translatesAutoresizingMaskIntoConstraints = false
        inner.backgroundColor = .white
        inner.layer.cornerRadius = 28
        inner.isUserInteractionEnabled = false
        shutterButton.addSubview(inner)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        guideLabel.translatesAutoresizingMaskIntoConstraints = false
        guideLabel.text = "  Center the warning light in the box  "
        guideLabel.textColor = .white
        guideLabel.font = .systemFont(ofSize: 15, weight: .medium)
        guideLabel.textAlignment = .center
        guideLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        guideLabel.layer.cornerRadius = 14
        guideLabel.clipsToBounds = true
        view.addSubview(guideLabel)

        NSLayoutConstraint.activate([
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            shutterButton.widthAnchor.constraint(equalToConstant: 72),
            shutterButton.heightAnchor.constraint(equalToConstant: 72),
            inner.centerXAnchor.constraint(equalTo: shutterButton.centerXAnchor),
            inner.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
            inner.widthAnchor.constraint(equalToConstant: 56),
            inner.heightAnchor.constraint(equalToConstant: 56),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            guideLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            guideLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            guideLabel.heightAnchor.constraint(equalToConstant: 36),
            guideSquare.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            guideSquare.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: guideYOffset),
            guideSquare.widthAnchor.constraint(equalToConstant: guideSize),
            guideSquare.heightAnchor.constraint(equalToConstant: guideSize),
        ])
    }

    private func addCornerAccents(to target: UIView) {
        let len: CGFloat = 28, w: CGFloat = 3.5
        let color = UIColor.systemBlue

        for (isRight, isBottom) in [(false,false),(true,false),(false,true),(true,true)] {
            let h = UIView(); let v = UIView()
            h.backgroundColor = color; v.backgroundColor = color
            h.translatesAutoresizingMaskIntoConstraints = false
            v.translatesAutoresizingMaskIntoConstraints = false
            h.layer.cornerRadius = w/2; v.layer.cornerRadius = w/2
            target.addSubview(h); target.addSubview(v)

            NSLayoutConstraint.activate([
                h.widthAnchor.constraint(equalToConstant: len),
                h.heightAnchor.constraint(equalToConstant: w),
                v.widthAnchor.constraint(equalToConstant: w),
                v.heightAnchor.constraint(equalToConstant: len),
            ])

            if isRight {
                h.trailingAnchor.constraint(equalTo: target.trailingAnchor, constant: -1).isActive = true
                v.trailingAnchor.constraint(equalTo: target.trailingAnchor, constant: -1).isActive = true
            } else {
                h.leadingAnchor.constraint(equalTo: target.leadingAnchor, constant: 1).isActive = true
                v.leadingAnchor.constraint(equalTo: target.leadingAnchor, constant: 1).isActive = true
            }
            if isBottom {
                h.bottomAnchor.constraint(equalTo: target.bottomAnchor, constant: -1).isActive = true
                v.bottomAnchor.constraint(equalTo: target.bottomAnchor, constant: -1).isActive = true
            } else {
                h.topAnchor.constraint(equalTo: target.topAnchor, constant: 1).isActive = true
                v.topAnchor.constraint(equalTo: target.topAnchor, constant: 1).isActive = true
            }
        }
    }

    // MARK: - Actions

    @objc private func capturePhoto() {
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        UIView.animate(withDuration: 0.1, animations: {
            self.shutterButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) { self.shutterButton.transform = .identity }
        }
    }

    @objc private func closeTapped() { delegate?.didCancel() }

    @objc private func handleTapToFocus(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: view)
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
        guard let device = (session.inputs.first as? AVCaptureDeviceInput)?.device else { return }
        do {
            try device.lockForConfiguration()
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = devicePoint
                device.focusMode = .autoFocus
            }
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = devicePoint
                device.exposureMode = .autoExpose
            }
            device.unlockForConfiguration()
        } catch {}

        let fv = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        fv.center = point
        fv.layer.borderColor = UIColor.yellow.cgColor
        fv.layer.borderWidth = 2; fv.layer.cornerRadius = 8; fv.alpha = 0
        view.addSubview(fv)
        UIView.animate(withDuration: 0.15, animations: {
            fv.alpha = 1; fv.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 0.5, animations: { fv.alpha = 0 }) { _ in fv.removeFromSuperview() }
        }
    }

    // MARK: - Crop to guide region (ORIENTATION-AWARE)

    /// Crops the captured photo to match the guide box on screen.
    ///
    /// The key challenge: AVCapturePhoto gives us an image whose cgImage is in the
    /// camera sensor's native orientation (landscape), but the UIImage has an
    /// .imageOrientation property (typically .right for portrait photos). We must
    /// first normalize the image to .up orientation, THEN crop in screen-matching
    /// pixel coordinates.
    private func cropToGuideRegion(_ image: UIImage) -> UIImage {
        // Step 1: Render the image into a new context that applies the orientation
        // transform. After this, the pixel layout matches what the user saw on screen.
        guard let normalized = normalizeOrientation(image) else { return image }
        guard let cgImage = normalized.cgImage else { return image }

        let imgW = CGFloat(cgImage.width)
        let imgH = CGFloat(cgImage.height)
        let viewSize = view.bounds.size

        // Step 2: Compute how .resizeAspectFill maps the (now correctly oriented) image to the view
        let viewAspect = viewSize.width / viewSize.height
        let imgAspect = imgW / imgH

        var visibleRect: CGRect
        if imgAspect > viewAspect {
            // Image wider than view -> cropped on left/right
            let visW = imgH * viewAspect
            visibleRect = CGRect(x: (imgW - visW) / 2, y: 0, width: visW, height: imgH)
        } else {
            // Image taller than view -> cropped on top/bottom
            let visH = imgW / viewAspect
            visibleRect = CGRect(x: 0, y: (imgH - visH) / 2, width: imgW, height: visH)
        }

        // Step 3: Map guide square from view points to image pixels
        let guideCX = viewSize.width / 2
        let guideCY = viewSize.height / 2 + guideYOffset
        let guideRect = CGRect(x: guideCX - guideSize / 2, y: guideCY - guideSize / 2,
                               width: guideSize, height: guideSize)

        let sx = visibleRect.width / viewSize.width
        let sy = visibleRect.height / viewSize.height

        var crop = CGRect(
            x: visibleRect.origin.x + guideRect.origin.x * sx,
            y: visibleRect.origin.y + guideRect.origin.y * sy,
            width: guideRect.width * sx,
            height: guideRect.height * sy
        )

        // 10% padding
        crop = crop.insetBy(dx: -crop.width * 0.1, dy: -crop.height * 0.1)
        // Clamp
        crop = crop.intersection(CGRect(x: 0, y: 0, width: imgW, height: imgH))

        guard !crop.isEmpty, let cropped = cgImage.cropping(to: crop) else { return image }
        return UIImage(cgImage: cropped)  // orientation is .up after normalization
    }

    /// Renders the UIImage into a new bitmap context so that the pixel data
    /// matches the visual orientation. This eliminates the orientation flag entirely.
    private func normalizeOrientation(_ image: UIImage) -> UIImage? {
        if image.imageOrientation == .up { return image }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized
    }

    private func showError(_ msg: String) {
        let l = UILabel(); l.text = msg; l.textColor = .white; l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(l)
        l.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        l.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let fullImage = UIImage(data: data) else { return }
        let cropped = cropToGuideRegion(fullImage)
        delegate?.didCapture(image: cropped)
    }
}
