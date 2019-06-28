//
//  Copyright © 2019 aleksandrpravda. All rights reserved.
//

import Alamofire
import CoreLocation

private enum SetupResult {
    case success
    case notAuthorized
}

protocol NetworkServiceProtocol {
    func getWeather(callback: @escaping ([String: Any]?, Error?) -> Void)
}

class NetworkService: NSObject, NetworkServiceProtocol {
    private let apiKey = "20c89ae2f01e039e9395a27ff842bf2e"
    private let networkQueue = DispatchQueue(label: "ttweather_network_queue")
    private let locationManager: CLLocationManager
    private var setupResult: SetupResult = .notAuthorized
    private let poligonRange = 0.002
    init(with coreLocationManager: CLLocationManager) {
        self.locationManager = coreLocationManager
        super.init()
        if !CLLocationManager.locationServicesEnabled() {
            return
        }
        self.setupResult = .success
    }
    
    func getWeather(callback: @escaping ([String: Any]?, Error?) -> Void) {
        self.networkQueue.async {
            switch self.setupResult {
            case .success:
                self.getPolygon { dictionary, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            callback(nil, error)
                        }
                        return
                    }
                    if let message = dictionary?["message"] as? String {
                        DispatchQueue.main.async {
                            let error = NSError(domain: "", code: 1, userInfo:[NSLocalizedDescriptionKey: message])
                            callback(nil, error)
                        }
                        return
                    }
                    guard let poliId = dictionary?["id"] else {
                        DispatchQueue.main.async {
                            let error = NSError(domain: "", code: 1, userInfo:[NSLocalizedDescriptionKey: ""])
                            callback(nil, error)
                        }
                        return
                    }
                    let stringURL = "http://api.agromonitoring.com/agro/1.0/weather?polyid=\(poliId)&appid=\(self.apiKey)"
                    self.makeRequest(with: URL(string: stringURL)!, method: "GET", parameters: nil) { dictionary, error in
                        DispatchQueue.main.async {
                            callback(dictionary, error)
                        }
                    }
                }
            case .notAuthorized:
                DispatchQueue.main.async {
                    let error = NSError(domain: "", code: 2, userInfo:[NSLocalizedDescriptionKey: NSLocalizedString("CLLocation not autorised", comment: "")])
                    callback(nil, error)
                }
            }
        }
    }
    
    private func getPolygon(callback: @escaping ([String: Any]?, Error?) -> Void) {
        let stringURL = "http://api.agromonitoring.com/agro/1.0/polygons?appid=\(apiKey)"
        self.makeRequest(with: URL(string: stringURL)!, method: "POST", parameters: self.poligonParams(), callback: callback)
    }
    
    private func makeRequest(with url: URL, method: String, parameters: Data?, callback: @escaping ([String: Any]?, Error?) -> Void) {
        var request = URLRequest(url: url)
        request.httpBody = parameters
        request.httpMethod = method
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        Alamofire.request(request)
            .debugLog()
            .response(
        responseSerializer: DataRequest.jsonResponseSerializer()) { response in
            switch response.result {
            case .success(let value):
                guard let dictionary = value as? [String: Any] else {
                    let error = NSError(domain: "", code: 3, userInfo:[NSLocalizedDescriptionKey: NSLocalizedString("Data Response error", comment: "")])
                    callback(nil, error)
                    return
                }
                print("Response dict: \(dictionary)")
                callback(dictionary, nil)
            case .failure(let error):
                callback(nil, error)
            }
        }
    }
    
    private func poligonParams() -> Data? {
        let location = self.locationManager.location!
        let location1 = CLLocationCoordinate2DMake(location.coordinate.latitude - self.poligonRange, location.coordinate.longitude - self.poligonRange)
        let location2 = CLLocationCoordinate2DMake(location.coordinate.latitude + self.poligonRange, location.coordinate.longitude - self.poligonRange)
        let location3 = CLLocationCoordinate2DMake(location.coordinate.latitude + self.poligonRange, location.coordinate.longitude + self.poligonRange)
        let location4 = CLLocationCoordinate2DMake(location.coordinate.latitude - self.poligonRange, location.coordinate.longitude + self.poligonRange)
        let str = "{ \"name\":\"Polygon Sample\", \"geo_json\":{ \"type\":\"Feature\", \"properties\":{ }, \"geometry\":{ \"type\":\"Polygon\", \"coordinates\":[ [ [\(location1.longitude), \(location1.latitude)], [\(location2.longitude), \(location2.latitude)], [ \(location3.longitude), \(location3.latitude)], [\(location4.longitude), \(location4.latitude)], [\(location1.longitude), \(location1.latitude)] ] ] } } }"
        return Data(str.utf8)
    }
    
    deinit {
        self.networkQueue.suspend()
    }
}

extension Request {
    public func debugLog() -> Self {
        #if DEBUG
        debugPrint(self)
        #endif
        return self
    }
}
