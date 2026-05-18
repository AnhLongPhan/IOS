import CoreLocation
import Foundation
import ImageIO
import Photos

struct ImageMetadataService {
    func coordinate(fromPhotoLibraryAssetIdentifier identifier: String?) async -> CLLocationCoordinate2D? {
        guard let identifier else { return nil }

        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        let resolvedStatus: PHAuthorizationStatus

        switch status {
        case .notDetermined:
            resolvedStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        default:
            resolvedStatus = status
        }

        guard resolvedStatus == .authorized || resolvedStatus == .limited else {
            return nil
        }

        let result = PHAsset.fetchAssets(
            withLocalIdentifiers: [identifier],
            options: nil
        )

        guard let asset = result.firstObject,
              let coordinate = asset.location?.coordinate,
              CLLocationCoordinate2DIsValid(coordinate) else {
            return nil
        }

        return coordinate
    }

    func coordinate(from imageData: Data) -> CLLocationCoordinate2D? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] else {
            return nil
        }

        guard let latitude = gps[kCGImagePropertyGPSLatitude] as? Double,
              let longitude = gps[kCGImagePropertyGPSLongitude] as? Double else {
            return nil
        }

        let latitudeRef = (gps[kCGImagePropertyGPSLatitudeRef] as? String)?.uppercased()
        let longitudeRef = (gps[kCGImagePropertyGPSLongitudeRef] as? String)?.uppercased()

        let resolvedLatitude = latitudeRef == "S" ? -latitude : latitude
        let resolvedLongitude = longitudeRef == "W" ? -longitude : longitude

        guard CLLocationCoordinate2DIsValid(
            CLLocationCoordinate2D(latitude: resolvedLatitude, longitude: resolvedLongitude)
        ) else {
            return nil
        }

        return CLLocationCoordinate2D(latitude: resolvedLatitude, longitude: resolvedLongitude)
    }
}
