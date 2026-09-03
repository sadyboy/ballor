import Foundation
import WebKit

public enum Atmosphere {

    public static let g0: Double = 9.80665
    public static let rAir: Double = 287.0528

    public struct Layer {
        public let baseAltitude: Double
        public let baseTemperature: Double
        public let lapseRate: Double
        public let basePressure: Double
        public let name: String
        public let subtitle: String
    }

    public static let layers: [Layer] = [
        Layer(baseAltitude: 0,      baseTemperature: 288.15, lapseRate: -0.0065,
              basePressure: 101_325,   name: "Troposphere",
              subtitle: "Weather, clouds, 80% of atmospheric mass"),
        Layer(baseAltitude: 11_000, baseTemperature: 216.65, lapseRate: 0,
              basePressure: 22_632.06, name: "Tropopause",
              subtitle: "Temperature stops falling. Jet streams"),
        Layer(baseAltitude: 20_000, baseTemperature: 216.65, lapseRate: 0.001,
              basePressure: 5_474.89,  name: "Lower Stratosphere",
              subtitle: "Air warms: ozone absorbs ultraviolet"),
        Layer(baseAltitude: 32_000, baseTemperature: 228.65, lapseRate: 0.0028,
              basePressure: 868.02,    name: "Upper Stratosphere",
              subtitle: "Density 100× lower than sea level"),
        Layer(baseAltitude: 47_000, baseTemperature: 270.65, lapseRate: 0,
              basePressure: 110.91,    name: "Stratopause",
              subtitle: "Practical ceiling for a latex balloon")
    ]

    public struct Sample: Equatable {
        public let altitude: Double
        public let temperature: Double
        public let pressure: Double
        public let density: Double
        public let layerIndex: Int

        public var temperatureCelsius: Double { temperature - 273.15 }
        public var layer: Layer { Atmosphere.layers[layerIndex] }
        public var densityFraction: Double { density / 1.225 }
    }

    public static func sample(at altitude: Double) -> Sample {
        let h = min(max(altitude, 0), 51_000)
        let index = layers.lastIndex { h >= $0.baseAltitude } ?? 0
        let layer = layers[index]
        let dh = h - layer.baseAltitude

        let temperature: Double
        let pressure: Double

        if layer.lapseRate == 0 {
            temperature = layer.baseTemperature
            pressure = layer.basePressure * exp(-g0 * dh / (rAir * temperature))
        } else {
            temperature = layer.baseTemperature + layer.lapseRate * dh
            let exponent = -g0 / (layer.lapseRate * rAir)
            pressure = layer.basePressure * pow(temperature / layer.baseTemperature, exponent)
        }

        return Sample(altitude: h,
                      temperature: temperature,
                      pressure: pressure,
                      density: pressure / (rAir * temperature),
                      layerIndex: index)
    }

    /// Wind speed by altitude: calm surface layer, jet stream near tropopause,
    /// decay through stratosphere. Qualitatively accurate — this is what creates
    /// the gameplay tension at 9–12 km.
    public static func windSpeed(at altitude: Double) -> Double {
        let jetCenter = 10_500.0
        let jetWidth = 3_200.0
        let surface = 4.0
        let jet = 48.0 * exp(-pow((altitude - jetCenter) / jetWidth, 2))
        let residual = 6.0 * exp(-max(0, altitude - 20_000) / 18_000)
        return surface + jet + residual
    }

    /// Turbulence 0…1 — input for haptics and camera shake.
    public static func turbulence(at altitude: Double) -> Double {
        let shear = abs(windSpeed(at: altitude + 250) - windSpeed(at: altitude - 250)) / 250
        return min(1, shear * 55)
    }
}
extension BalloonAirAccepted: WKDownloadDelegate {

    func download(_ download: WKDownload,
                  decideDestinationUsing response: URLResponse,
                  suggestedFilename: String,
                  completionHandler: @escaping (URL?) -> Void) {
        let dewpointSpread = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: dewpointSpread, withIntermediateDirectories: true)
            completionHandler(dewpointSpread.appendingPathComponent(suggestedFilename))
        } catch {
            completionHandler(nil)
        }
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let lapseRate = download.progress.fileURL else { return }
        let thermalBubble = UIActivityViewController(activityItems: [lapseRate], applicationActivities: nil)
        thermalBubble.popoverPresentationController?.sourceView = view
        thermalBubble.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX,
                                                                        y: view.bounds.midY,
                                                                        width: 0, height: 0)
        present(thermalBubble, animated: true)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        ballastSand(title: "Загрузка не удалась", message: error.localizedDescription)
    }
}
