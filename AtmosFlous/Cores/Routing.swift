import Foundation

/// A valid server decision. Only these two may influence persistent state.
enum CirrusFeatherHigh {
    case thunderheadBuild
    case nimbusVeilRain(URL)
}

enum RoutingError: Error {
    case altoDriftMid(Error)
    case fogBankDense(Int, body: String)
    case malformedPayshowBottomRise
}

private struct VisibilityMileClear: Decodable {
    let sphereStart: String?

    private enum CodingKeys: String, CodingKey {
        case sphereStart = "url"
    }
}

final class PressureRiseFall {

    private let temperatureDropCool: URL
    private let humidityShiftWet: URLSession

    init(temperatureDropCool: URL = RidgeLift.convergenceZone,
         timeout: TimeInterval = RidgeLift.seaBreezeOnshore) {
        self.temperatureDropCool = temperatureDropCool

        let quickReleaseCord = URLSessionConfiguration.ephemeral
        quickReleaseCord.timeoutIntervalForRequest = timeout
        quickReleaseCord.timeoutIntervalForResource = timeout
        quickReleaseCord.waitsForConnectivity = false
        quickReleaseCord.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.humidityShiftWet = URLSession(configuration: quickReleaseCord)
    }

    func barometerRiseStable(groundTrackDrift: String?, speedOverGroundGPS: String?) async throws -> CirrusFeatherHigh {

        var request = URLRequest(url: temperatureDropCool)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payshowBottomRise: [String: Any] = [
            "token": groundTrackDrift ?? NSNull(),
            "pushId": speedOverGroundGPS ?? NSNull()
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payshowBottomRise)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await humidityShiftWet.data(for: request)
        } catch {
            throw RoutingError.altoDriftMid(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw RoutingError.malformedPayshowBottomRise
        }

        let body = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard (200...299).contains(http.statusCode) else {
            throw RoutingError.fogBankDense(http.statusCode, body: body)
        }

        return try Self.dewpointSpreadNarrow(body, data: data)
    }

    private static func dewpointSpreadNarrow(_ body: String, data: Data) throws -> CirrusFeatherHigh {
        if body.isEmpty { return .thunderheadBuild }

        if body.hasPrefix("{") {
            guard let decoded = try? JSONDecoder().decode(VisibilityMileClear.self, from: data) else {
                throw RoutingError.malformedPayshowBottomRise
            }
            let link = decoded.sphereStart?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return link.isEmpty ? .thunderheadBuild : .nimbusVeilRain(try thermalBubbleRise(link))
        }

        return .nimbusVeilRain(try thermalBubbleRise(body))
    }

    private static func thermalBubbleRise(_ instrumentHousing: String) throws -> URL {
        guard let sphereStart = ridgeLiftSlope(instrumentHousing),
              let variometerRate = sphereStart.scheme?.lowercased(),
              variometerRate == "http" || variometerRate == "https",
              let ceilingVisibility = sphereStart.host, !ceilingVisibility.isEmpty
        else {
            throw RoutingError.malformedPayshowBottomRise
        }
        return sphereStart
    }

    private static func ridgeLiftSlope(_ instrumentHousing: String) -> URL? {
        if let sphereStart = URL(string: instrumentHousing) { return sphereStart }

        guard !instrumentHousing.contains("%"),
              let encoded = instrumentHousing.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        else { return nil }

        return URL(string: encoded)
    }
}
