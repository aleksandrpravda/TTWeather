//
//  Copyright © 2019 aleksandrpravda. All rights reserved.
//

import UIKit
import YandexMobileMetrica
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var dateView: UIView!
    @IBOutlet weak var dateDayLael: UILabel!
    @IBOutlet weak var dateMonthLabel: UILabel!
    @IBOutlet weak var dateYearLabel: UILabel!
    @IBOutlet weak var dateHoursLabel: UILabel!
    @IBOutlet weak var dateMinLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var pressureLabel: UILabel!
    @IBOutlet weak var temperatureSeparator: UIView!
    @IBOutlet weak var pressureSeparator: UIView!
    @IBOutlet weak var temperatureValueLabel: UILabel!
    @IBOutlet weak var pressureValueLabel: UILabel!
    
    var networkService: NetworkService!
    var gradientLayer: CAGradientLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !CLLocationManager.locationServicesEnabled() {
            return
        }
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        self.networkService = NetworkService(with: locationManager)
        
        self.gradientLayer = getGradientLayer()
        self.view.layer.insertSublayer(self.gradientLayer, at: 0)
        
        self.setInitialState()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.gradientLayer.frame = self.view.bounds
    }

    @IBAction func onBtnPress(_ sender: UIButton) {
        self.setInitialState()
        self.apiWeatherCall()
        YMMYandexMetrica.reportEvent("button_press", parameters: nil, onFailure: nil)
    }
    
    func setInitialState() {
        self.dateView.layer.opacity = 0
        self.temperatureSeparator.layer.opacity = 0
        self.temperatureLabel.layer.opacity = 0
        self.pressureSeparator.layer.opacity = 0
        self.pressureLabel.layer.opacity = 0
        
        self.temperatureValueLabel.font = UIFont.systemFont(ofSize: 0)
        self.pressureValueLabel.font = UIFont.systemFont(ofSize: 0)
        
        self.temperatureSeparator.layer.removeAllAnimations()
        self.temperatureLabel.layer.removeAllAnimations()
        self.temperatureValueLabel.layer.removeAllAnimations()
        self.pressureSeparator.layer.removeAllAnimations()
        self.pressureLabel.layer.removeAllAnimations()
        self.pressureValueLabel.layer.removeAllAnimations()
    }
    
    func apiWeatherCall() {
        self.networkService.getWeather { dictionary, error in
            if let error = error {
                self.apiErrorAlert(error)
                return
            }
            guard let dictionary = dictionary else {
               print("ViewController::viewDidLoad NetworkServiceProtocol::getWeather data is nil")// TODO add alert
                return
            }
            self.onDataLoaded(dictionary)
        }
    }
    
    func onDataLoaded(_ dictionary: [String: Any]) {
        guard let dt = dictionary["dt"] as? Int, let mainDictionary = dictionary["main"] as? [String: Any], let pressure = mainDictionary["pressure"] as? Double, let temperature = mainDictionary["temp"] as? Double else {
            return
        }
        self.update(date: Date.init(timeIntervalSince1970: TimeInterval(dt)))
        
        self.fadeIn(layer: self.temperatureSeparator.layer, duration: 0.8, delay: 0.0)
        self.fadeIn(layer: self.temperatureLabel.layer, duration: 0.8, delay: 0.4)
        
        self.fadeIn(layer: self.pressureSeparator.layer, duration: 0.8, delay: 0.2)
        self.fadeIn(layer: self.pressureLabel.layer, duration: 0.8, delay: 0.6)
        
        self.pressureValueLabel.layer.opacity = 1
        self.temperatureValueLabel.layer.opacity = 1
        
        self.coundown(label: self.temperatureValueLabel, fromVAlue: 0, toValue: temperature - 273.15, toFontSize: 22, delay: .milliseconds(120), duration: 1.2, valueFormat: "%.0f", "\u{00B0}")
        self.coundown(label: self.pressureValueLabel, fromVAlue: 0, toValue: pressure, toFontSize: 22, delay: .milliseconds(140), duration: 1.2, valueFormat: "%.1f")
    }
    
    func update(label: UILabel, fontSize: Float, value: String, _ suffix: String? = nil) {
        label.text = value + (suffix ?? "")
        label.font = UIFont.systemFont(ofSize: CGFloat(fontSize))
    }
    
    func coundown(label: UILabel, fromVAlue: Double, toValue: Double, toFontSize: Double, delay: DispatchTimeInterval, duration: Double, valueFormat: String, _ suffix: String? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let timeInterval: Double = 0.05;
            var coundoun = duration
            var fontSize: Double = 0.0
            var value: Double = 0.0
            let steps = duration / timeInterval
            let fontDelta = (toFontSize + 5) / steps
            let valueDelta = (toValue - fromVAlue) / steps
            var easyOutCountDown = 0.5
            Timer.scheduledTimer(withTimeInterval: TimeInterval(timeInterval), repeats: true) { [weak self] timer in
                coundoun -= timeInterval
                if coundoun <= 0 {
                    easyOutCountDown -= timeInterval
                    if easyOutCountDown <= 0 {
                        timer.invalidate()
                    }
                    fontSize -= 0.5
                } else {
                    value += valueDelta
                    fontSize += fontDelta
                }
                self?.update(label: label, fontSize: Float(fontSize), value: String(format: valueFormat, value), suffix)
            }
        }
    }
    
    func update(date: Date) {
        self.dateView.layer.opacity = 1
        let calendar = Calendar.current
        self.dateYearLabel.text = self.formatDate(value: calendar.component(.year, from: date))
        self.dateMonthLabel.text = self.formatDate(value: calendar.component(.month, from: date))
        self.dateDayLael.text = self.formatDate(value: calendar.component(.day, from: date))
        self.dateHoursLabel.text = self.formatDate(value: calendar.component(.hour, from: date))
        self.dateMinLabel.text = self.formatDate(value: calendar.component(.minute, from: date))
    }
    
    func getGradientLayer() -> CAGradientLayer {
        let colorTop = UIColor(red: 0.0 / 255.0, green: 0.0 / 255.0, blue: 200.0 / 255.0, alpha: 1.0).cgColor
        let colorBottom = UIColor(red: 255.0 / 255.0, green: 255.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0).cgColor
        
        let layer = CAGradientLayer()
        layer.colors = [colorTop, colorBottom]
        layer.locations = [0.0, 0.5]
        return layer
    }
    
    func fadeIn(layer: CALayer, duration: Double, delay: Double) {
        let opacity = CABasicAnimation(keyPath: "opacity")
        opacity.duration = duration
        opacity.fromValue = 0.0
        opacity.toValue = 1.0
        opacity.beginTime = CACurrentMediaTime() + delay
        opacity.timingFunction = CAMediaTimingFunction(name: .easeOut)
        opacity.fillMode = CAMediaTimingFillMode.forwards
        opacity.isRemovedOnCompletion = false
        layer.add(opacity, forKey: "opacityAnimation")
    }
    
    func formatDate(value: Int) -> String {
        return value > 10 ? String(value) : "0" + String(value)
    }
    
    internal override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse, .restricted:
            self.apiWeatherCall()
            break
        case .denied:
            self.corelocationAlert()
            break
        case .notDetermined:
            self.corelocationAlert()
            break
        @unknown default:
            break
        }
    }
    
    func apiErrorAlert(_ error: Error) {
        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(
            UIAlertAction(
                title: NSLocalizedString("OK", comment: "Alert OK button"),
                style: .cancel,
                handler: nil
            )
        )
    }
    
    func corelocationAlert() {
        let changePrivacySetting = "App doesn't have permission to use the weather API, please change privacy settings"
        let alertController = UIAlertController(title: "Core Location", message: changePrivacySetting, preferredStyle: .alert)
        alertController.addAction(
            UIAlertAction(
                title: NSLocalizedString("OK", comment: "Alert OK button"),
                style: .cancel,
                handler: nil
            )
        )
        alertController.addAction(
            UIAlertAction(
                title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                style: .`default`,
                handler: { _ in
                    UIApplication.shared.open(
                        URL(string: UIApplication.openSettingsURLString)!,
                        options: [:],
                        completionHandler: nil
                    )
                }
            )
        )
        self.present(alertController, animated: true, completion: nil)
    }
}
