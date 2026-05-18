import AVFoundation
import UIKit

struct MomentVideoService {
    enum MomentVideoError: Error {
        case noImages
        case cannotCreateWriter
        case cannotCreatePixelBuffer
        case cannotRenderFrame
    }

    func createVideo(
        title: String,
        subtitle: String,
        checkIns: [CheckIn],
        durationPerPhoto: Double = 1.0,
        framesPerSecond: Int32 = 24,
        size: CGSize = CGSize(width: 720, height: 1280)
    ) async throws -> URL {
        let imageService = ImageStorageService()
        let images = checkIns.compactMap { checkIn -> (UIImage, CheckIn)? in
            guard let photoPath = checkIn.photoPath,
                  let image = imageService.load(filename: photoPath) else { return nil }
            return (image, checkIn)
        }

        guard !images.isEmpty else { throw MomentVideoError.noImages }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("TravelPin-Moment-")
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        try? FileManager.default.removeItem(at: outputURL)
        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height)
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false

        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: Int(size.width),
            kCVPixelBufferHeightKey as String: Int(size.height)
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: attributes
        )

        guard writer.canAdd(input) else { throw MomentVideoError.cannotCreateWriter }
        writer.add(input)

        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        let frameDuration = CMTime(value: 1, timescale: framesPerSecond)
        let framesPerPhoto = max(1, Int(durationPerPhoto * Double(framesPerSecond)))
        let transitionFrames = min(Int(0.35 * Double(framesPerSecond)), max(0, framesPerPhoto / 3))
        var frameIndex: Int64 = 0

        for index in images.indices {
            let current = images[index]
            let next = images.indices.contains(index + 1) ? images[index + 1] : nil

            for frameInPhoto in 0..<framesPerPhoto {
                try Task.checkCancellation()
                if frameIndex % 4 == 0 {
                    await Task.yield()
                }

                while !input.isReadyForMoreMediaData {
                    try await Task.sleep(for: .milliseconds(20))
                }

                let transitionProgress: Double
                if next != nil && transitionFrames > 0 && frameInPhoto >= framesPerPhoto - transitionFrames {
                    transitionProgress = Double(frameInPhoto - (framesPerPhoto - transitionFrames) + 1) / Double(transitionFrames)
                } else {
                    transitionProgress = 0
                }

                let zoomProgress = Double(frameInPhoto) / Double(max(framesPerPhoto - 1, 1))

                guard let buffer = makePixelBuffer(
                    image: current.0,
                    nextImage: next?.0,
                    checkIn: current.1,
                    title: title,
                    subtitle: subtitle,
                    size: size,
                    zoomProgress: zoomProgress,
                    transitionProgress: transitionProgress,
                    adaptor: adaptor
                ) else {
                    throw MomentVideoError.cannotCreatePixelBuffer
                }

                let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameIndex))
                adaptor.append(buffer, withPresentationTime: presentationTime)
                frameIndex += 1
            }
        }

        input.markAsFinished()
        await writer.finishWriting()

        if let error = writer.error {
            throw error
        }

        return outputURL
    }

    private func makePixelBuffer(
        image: UIImage,
        nextImage: UIImage?,
        checkIn: CheckIn,
        title: String,
        subtitle: String,
        size: CGSize,
        zoomProgress: Double,
        transitionProgress: Double,
        adaptor: AVAssetWriterInputPixelBufferAdaptor
    ) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(
            kCFAllocatorDefault,
            adaptor.pixelBufferPool!,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else { return nil }

        let renderedImage = renderFrameImage(
            image: image,
            nextImage: nextImage,
            checkIn: checkIn,
            title: title,
            subtitle: subtitle,
            size: size,
            zoomProgress: zoomProgress,
            transitionProgress: transitionProgress
        )

        guard let cgImage = renderedImage.cgImage else { return nil }

        context.clear(CGRect(origin: .zero, size: size))
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))

        return pixelBuffer
    }

    private func renderFrameImage(
        image: UIImage,
        nextImage: UIImage?,
        checkIn: CheckIn,
        title: String,
        subtitle: String,
        size: CGSize,
        zoomProgress: Double,
        transitionProgress: Double
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            UIColor.black.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()

            drawKenBurnsImage(
                image,
                in: size,
                zoomProgress: zoomProgress,
                alpha: 1
            )

            if let nextImage, transitionProgress > 0 {
                drawKenBurnsImage(
                    nextImage,
                    in: size,
                    zoomProgress: 0,
                    alpha: CGFloat(transitionProgress)
                )
            }

            let scale = size.width / 1080
            let overlayHeight = 440 * scale
            let horizontalPadding = 72 * scale
            let contentWidth = size.width - horizontalPadding * 2
            let overlayRect = CGRect(x: 0, y: size.height - overlayHeight, width: size.width, height: overlayHeight)
            UIColor.black.withAlphaComponent(0.46).setFill()
            UIBezierPath(rect: overlayRect).fill()

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .left
            paragraph.lineBreakMode = .byTruncatingTail

            drawText(
                title,
                in: CGRect(x: horizontalPadding, y: size.height - 390 * scale, width: contentWidth, height: 76 * scale),
                font: .boldSystemFont(ofSize: 54 * scale),
                color: .white,
                paragraph: paragraph
            )

            drawText(
                subtitle,
                in: CGRect(x: horizontalPadding, y: size.height - 310 * scale, width: contentWidth, height: 52 * scale),
                font: .systemFont(ofSize: 34 * scale, weight: .medium),
                color: UIColor.white.withAlphaComponent(0.88),
                paragraph: paragraph
            )

            drawText(
                checkIn.name,
                in: CGRect(x: horizontalPadding, y: size.height - 234 * scale, width: contentWidth, height: 52 * scale),
                font: .systemFont(ofSize: 38 * scale, weight: .semibold),
                color: .white,
                paragraph: paragraph
            )

            drawText(
                "\(checkIn.formattedDate) • \(checkIn.locationDisplay)",
                in: CGRect(x: horizontalPadding, y: size.height - 176 * scale, width: contentWidth, height: 44 * scale),
                font: .systemFont(ofSize: 28 * scale, weight: .regular),
                color: UIColor.white.withAlphaComponent(0.82),
                paragraph: paragraph
            )
        }
    }

    private func drawKenBurnsImage(
        _ image: UIImage,
        in targetSize: CGSize,
        zoomProgress: Double,
        alpha: CGFloat
    ) {
        let normalizedImage = normalizedImage(image)
        let baseRect = aspectFillRect(imageSize: normalizedImage.size, targetSize: targetSize)
        let zoom = 1 + CGFloat(zoomProgress) * 0.045
        let zoomedRect = baseRect.insetBy(
            dx: -baseRect.width * (zoom - 1) / 2,
            dy: -baseRect.height * (zoom - 1) / 2
        )

        normalizedImage.draw(in: zoomedRect, blendMode: .normal, alpha: alpha)
    }

    private func normalizedImage(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false

        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    private func drawText(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor,
        paragraph: NSParagraphStyle
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        text.draw(in: rect, withAttributes: attributes)
    }

    private func aspectFillRect(imageSize: CGSize, targetSize: CGSize) -> CGRect {
        let scale = max(targetSize.width / imageSize.width, targetSize.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        return CGRect(
            x: (targetSize.width - width) / 2,
            y: (targetSize.height - height) / 2,
            width: width,
            height: height
        )
    }
}
