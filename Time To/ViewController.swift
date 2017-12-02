//
//  ViewController.swift
//  Time To
//
//  Created by Antonio Carranza on 30/10/17.
//  Copyright © 2017 Antonio Carranza. All rights reserved.
//

import UIKit
import UserNotifications
import AVFoundation
import CoreLocation

struct TTDInterval {
    let timeInterval: TimeInterval
    let title: String
}

class ViewController: UIViewController, UNUserNotificationCenterDelegate, UIPickerViewDelegate, UIPickerViewDataSource, CLLocationManagerDelegate {

    //MARK: - Outlets
    
    @IBOutlet weak var intervalTimer: UIPickerView!
    @IBOutlet weak var soundSelector: UIPickerView!
    @IBOutlet weak var timeToButton: UIButton!
    @IBOutlet weak var restrictToCurrentLocationSwitch: UISwitch!
    @IBOutlet weak var restartCountdownWhenMovingSwitch: UISwitch!
    @IBOutlet weak var previewSoundSwitch: UISwitch!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var countDownLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var restrictToCurrentLocationLabel: UILabel!
    @IBOutlet weak var restartCountdownWhenMovingLabel: UILabel!
    @IBOutlet weak var intervalStackView: UIStackView!
    @IBOutlet weak var restrictToCurrentLocationInfoButton: UIButton!
    @IBOutlet weak var restartCountdownWhenMovingInfoButton: UIButton!
    
    //MARK: - Variables
    
    var setupInitialDisplayTimer = Timer()
    var checkLocalizationServicesAuthorizationStatusTimer = Timer()
    var statusTimer: Timer?
    var countdownTimer: Timer?
    var intervals: [TTDInterval] = [TTDInterval(timeInterval: (1*60), title: "1 minute"),
                                    TTDInterval(timeInterval: (15*60), title: "15 minutes"),
                                    TTDInterval(timeInterval: (30*60), title: "30 minutes"),
                                    TTDInterval(timeInterval: (45*69), title: "45 minutes"),
                                    TTDInterval(timeInterval: (60*60), title: "1 hour"),
                                    TTDInterval(timeInterval: (75*60), title: "1 hour and 15 minutes"),
                                    TTDInterval(timeInterval: (90*60), title: "1 hour and 30 minutes"),
                                    TTDInterval(timeInterval: (105*60), title: "1 hour and 45 minutes"),
                                    TTDInterval(timeInterval: (105*60), title: "2 hours, to late! 😡")]
    var sounds = ["Default","Ice","Lorry","Phone","Hyena"]
    var player: AVAudioPlayer?
    var stepsLocationManager:CLLocationManager!
    var significantLocationManager:CLLocationManager!
    var previousLocation: CLLocation?
    
    var restrictToCurrentLocationDateEnabled: Date?
    var restartCountdownWhenMovingDateEnabled: Date?
    
    var restrictToCurrentLocation: Bool = (UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.bool(forKey: "restrictToCurrentLocation"))! {
        didSet {
            print("Restrict to current location saved to \(restrictToCurrentLocation)")
            UserDefaults(suiteName: "group.es.365d.Time-To-Do")!.set(restrictToCurrentLocation, forKey: "restrictToCurrentLocation")
            setSignificantLocationManager(enable: restrictToCurrentLocation && currentStatus)
        }
    }
    
    var restartCountdownWhenMoving: Bool = (UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.bool(forKey: "restartCountdownWhenMoving"))! {
        didSet {
            print("Restart countdown when moving saved to \(restartCountdownWhenMoving)")
            UserDefaults(suiteName: "group.es.365d.Time-To-Do")!.set(restartCountdownWhenMoving, forKey: "restartCountdownWhenMoving")
            setStepsLocationManager(enable: restartCountdownWhenMoving && currentStatus)
        }
    }
    
    var distanceInMetersFromPreviousLocation: Double = (UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.double(forKey: "distanceInMetersFromPreviousLocation"))! {
        didSet {
            print("distance in metters from previous location saved to \(distanceInMetersFromPreviousLocation)")
            UserDefaults(suiteName: "group.es.365d.Time-To-Do")!.set(distanceInMetersFromPreviousLocation, forKey: "distanceInMetersFromPreviousLocation")
        }
    }
    
    var previewSound: Bool = (UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.bool(forKey: "previewSound"))! {
        didSet {
            print("Preview Sound saved to \(previewSound)")
            UserDefaults(suiteName: "group.es.365d.Time-To-Do")!.set(previewSound, forKey: "previewSound")
        }
    }
    
    var currentSound: Int = (UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.integer(forKey: "currentSound"))! {
        didSet {
            print("Selected Sound saved to \(sounds[currentSound])")
            UserDefaults(suiteName: "group.es.365d.Time-To-Do")!.set(currentSound, forKey: "currentSound")
        }
    }
    var currentInterval: TimeInterval = (UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.double(forKey: "currentTimeInterval"))! {
        didSet {
            print("Selected Interval saved to \(currentInterval)")
            UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.set(currentInterval, forKey: "currentTimeInterval")
        }
    }
    var currentStatus: Bool = false {
        didSet {
            print("Status saved to \(currentStatus)")
            UserDefaults(suiteName: "group.es.365d.Time-To-Do")!.set(currentStatus, forKey: "currentStatus")
            setSignificantLocationManager(enable: restrictToCurrentLocation && currentStatus)
            setStepsLocationManager(enable: restartCountdownWhenMoving && currentStatus)
            animateTimeToButton()
            if currentStatus {
                showMessage(NSLocalizedString("Countdown started", comment: ""), clearMessage: true)
                self.timeToButton.setTitle("Stop", for: .normal)
                self.statusLabel.text = formatDate(dateToFormat: nextNotificationDate!, dateStyle: .medium, timeStyle: .medium)
                if statusTimer == nil { statusTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(checkStatus), userInfo: nil, repeats: true) }
                if countdownTimer == nil { countdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updatePendingTime), userInfo: nil, repeats: true) }
            } else {
                showMessage("Countdown stopped", clearMessage: true)
                self.timeToButton.setTitle("Start", for: .normal)
                self.nextNotificationDate = nil
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                if statusTimer != nil {
                    statusTimer!.invalidate()
                    statusTimer = nil
                }
                if countdownTimer != nil {
                    countdownTimer!.invalidate()
                    countdownTimer = nil
                }
                self.statusLabel.text = "Nothing Scheduled"
                self.countDownLabel.text = "00:00"
            }
        }
    }
    
    var nextNotificationDate: Date? = UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.object(forKey: "nextNotificationDate") as? Date {
        didSet {
            print("nextNotificationDate saved to \(nextNotificationDate?.description ?? "not set or set to nil")")
            UserDefaults(suiteName: "group.es.365d.Time-To-Do")!.set(nextNotificationDate, forKey: "nextNotificationDate")
        }
    }
    
    var lastLocationDate: Date? = UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.object(forKey: "lastLocationDate") as? Date {
        didSet {
            print("lastLocationDate saved to \(lastLocationDate?.description ?? "not set or set to nil")")
            UserDefaults(suiteName: "group.es.365d.Time-To-Do")!.set(lastLocationDate, forKey: "lastLocationDate")
        }
    }
    
    //MARK: - Authorization functions
    
    func checkNotificationsAuthorizationStatus() {
        let centre = UNUserNotificationCenter.current()
        centre.getNotificationSettings { (settings) in
            if settings.authorizationStatus != UNAuthorizationStatus.authorized {
                self.showNotificationsHelpViewController()
            } else {
                print("Notifications Authorised")
            }
        }
    }
    
    func showNotificationsHelpViewController() {
        DispatchQueue.main.async{
            let dvc = self.storyboard?.instantiateViewController(withIdentifier: "HelpNotificationsViewController") as! HelpViewController
            self.present(dvc, animated: true, completion: nil)
        }
    }
    
    @objc func checkLocalizationAuthorizationStatus() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .notDetermined:
            self.restartCountdownWhenMovingSwitch.isEnabled = true
            self.restartCountdownWhenMovingSwitch.setOn(restartCountdownWhenMoving, animated: true)
            self.restartCountdownWhenMovingInfoButton.tintColor = UIColor.blue
            self.restrictToCurrentLocationSwitch.isEnabled = true
            self.restrictToCurrentLocationSwitch.setOn(restrictToCurrentLocation, animated: true)
            self.restrictToCurrentLocationInfoButton.tintColor = UIColor.blue
            
        case .authorizedWhenInUse:
            self.restartCountdownWhenMovingSwitch.isEnabled = true
            self.restartCountdownWhenMovingSwitch.setOn(restartCountdownWhenMoving, animated: true)
            self.restartCountdownWhenMovingInfoButton.tintColor = UIColor.blue
            self.restrictToCurrentLocationSwitch.isEnabled = false
            self.restrictToCurrentLocationSwitch.setOn(false, animated: true)
            self.restrictToCurrentLocationSwitch.setOn(false, animated: true)
            self.restrictToCurrentLocationInfoButton.tintColor = UIColor.red
            animateInfoButton(self.restrictToCurrentLocationInfoButton)
            
        case .denied, .restricted:
            self.restartCountdownWhenMovingSwitch.isEnabled = false
            self.restartCountdownWhenMovingSwitch.setOn(false, animated: true)
            self.restartCountdownWhenMovingInfoButton.tintColor = UIColor.red
            animateInfoButton(self.restartCountdownWhenMovingInfoButton)
            self.restrictToCurrentLocationSwitch.isEnabled = false
            self.restrictToCurrentLocationInfoButton.tintColor = UIColor.red
            self.restrictToCurrentLocationSwitch.setOn(false, animated: true)
            animateInfoButton(self.restrictToCurrentLocationInfoButton)
            self.restrictToCurrentLocationSwitch.setOn(false, animated: true)
            self.restartCountdownWhenMovingSwitch.setOn(false, animated: true)
            
        }
    }

    //MARK: - Application lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        UNUserNotificationCenter.current().delegate = self
        // Update controls to saved status
        setupInitialDisplayTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(setInitialControlsValues), userInfo: nil, repeats: false)
        //RunLoop.main.add(timer, forMode: .commonModes)
        messageLabel.textColor = UIColor(named: "messageTextColor")
        checkLocalizationServicesAuthorizationStatusTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(checkLocalizationAuthorizationStatus), userInfo: nil, repeats: true)
        checkNotificationsAuthorizationStatus()
        self.timeToButton.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("Current Status \(currentStatus)")
        print("Current Interval \(currentInterval)")
        print("Current Sound \(currentSound)")
        print("Next Notification Date \(nextNotificationDate?.description ?? "not set or nil")")
        print("Restrict to current location status is \(restrictToCurrentLocation)")
        print("Restart Countdown when moving status is \(restartCountdownWhenMoving)")
        print("Preview Sound status is \(previewSound)")
        checkStatus()
        checkLocalizationAuthorizationStatus()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func setInitialControlsValues() {
        
        //Set the Interval Picker to last saved value or to 1 hour
//        if currentInterval == 0 {currentInterval = 3600}
//
//        var c = DateComponents()
//
//        c.year = Calendar.current.component(.year, from: Date())
//        c.month = Calendar.current.component(.month, from: Date())
//        c.day = Calendar.current.component(.day, from: Date())
//        c.hour = 0
//        c.minute = 0
//        c.second = Int(currentInterval)
//
//        if let intervalDate = Calendar(identifier: .gregorian).date(from: c) {
//            self.intervalTimer.setDate(intervalDate, animated: true)
//            self.intervalTimer.maximumDate = Calendar(identifier: .gregorian).date(from: c)
//        }
        
        //Set the Sound selected for Notification
        self.soundSelector.selectRow(currentSound, inComponent: 0, animated: true)
        
        //Set the switches Values
        self.previewSoundSwitch.setOn(previewSound, animated: true)
        
        animateTimeToButton()
        
    }
    
    @objc func checkStatus() {
        let newStatus = (UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.bool(forKey: "currentStatus"))!
        if newStatus != currentStatus { currentStatus = newStatus }
    }
    
    //MARK: - Localization Functions
    
    func setStepsLocationManager(enable: Bool) {
        if enable {
            print("+ Restart countdown when moving manager enabled")
            stepsLocationManager = CLLocationManager()
            stepsLocationManager.delegate = self
            stepsLocationManager.desiredAccuracy = kCLLocationAccuracyBest
            stepsLocationManager.distanceFilter = 10
            stepsLocationManager.allowsBackgroundLocationUpdates = true
            stepsLocationManager.requestAlwaysAuthorization()
            stepsLocationManager.startUpdatingLocation()
            restartCountdownWhenMovingDateEnabled = Date()
        } else {
            if stepsLocationManager != nil {
                stepsLocationManager.stopUpdatingLocation()
                stepsLocationManager = nil
            }
            print("- Restart countdown when moving manager disabled")
            //self.restrictToCurrentLocationLabel.layer.backgroundColor = UIColor.white.cgColor
        }
    }

    func setSignificantLocationManager(enable: Bool) {
        if enable {
            print("+ Restric to current location manager enabled")
            significantLocationManager = CLLocationManager()
            significantLocationManager.delegate = self
            significantLocationManager.allowsBackgroundLocationUpdates = true
            significantLocationManager.requestAlwaysAuthorization()
            significantLocationManager.startMonitoringSignificantLocationChanges()
            restrictToCurrentLocationDateEnabled = Date()
        } else {
            if significantLocationManager != nil {
                significantLocationManager.stopMonitoringSignificantLocationChanges()
                significantLocationManager = nil
            }
            print("- Restric to current location manager disabled")
            //self.restrictToCurrentLocationLabel.layer.backgroundColor = UIColor.white.cgColor
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        if previousLocation != nil {
            distanceInMetersFromPreviousLocation = userLocation.distance(from: previousLocation!)
            print("previous Location is \(previousLocation!)")
            print("Distance in meters is \(distanceInMetersFromPreviousLocation)")
        }
        previousLocation = userLocation
        print("Location Manager:\nLast Location Date is \(String(describing: lastLocationDate))")
        print("Current Location is \(userLocation)")
        
        if manager.distanceFilter == 10 {
            if Date() > restartCountdownWhenMovingDateEnabled!.addingTimeInterval(10) {
                print("Checking is need to restart counter")
                if self.restartCountdownWhenMoving && distanceInMetersFromPreviousLocation > 10 {
                    lastLocationDate = Date()
                    print("User moved \(distanceInMetersFromPreviousLocation) mts, restarting countdown")
                    scheduleNotification()
                    showMessage("Move detected, restarting countdown", clearMessage: true)
                }
            }
        } else {
            print("Checking if need to turn off notifications")
            if Date() > restrictToCurrentLocationDateEnabled!.addingTimeInterval(60) {
                currentStatus = false
                showMessage("Location changed at \(formatDate(dateToFormat: Date(), dateStyle: .none, timeStyle: .medium))", clearMessage: false)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error in location manager \(error)")
    }
    
    //MARK: - Auxiliary functions (Messages, formatDate)
    
    func previewSoundMethod() {
        
        let currentSoundName = sounds[currentSound]
        guard let url = Bundle.main.url(forResource: currentSoundName, withExtension: "wav") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            guard let player = player else { return }
            
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func showMessage(_ message: String, clearMessage: Bool) {
        self.messageLabel.text = message
        UIView.animate(withDuration: 2.0, animations: {
            self.messageLabel.layer.backgroundColor = UIColor(named: "messageBackgroundColor")?.cgColor
        })
        if clearMessage {
            UIView.animate(withDuration: 2.0, delay: 5.0, options: UIViewAnimationOptions(), animations: {
                self.messageLabel.layer.backgroundColor = UIColor.clear.cgColor
            }, completion: nil)
        }
    }
    
    func formatDate(dateToFormat: Date, dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: dateToFormat)
    }
    
    func animateInfoButton(_ sender: UIButton) {
        
        sender.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        
        UIView.animate(withDuration: 2.0,
                       delay: 0,
                       usingSpringWithDamping: CGFloat(0.20),
                       initialSpringVelocity: CGFloat(6.0),
                       options: UIViewAnimationOptions.allowUserInteraction,
                       animations: {
                        sender.transform = CGAffineTransform.identity
        },
                       completion: { Void in()  }
        )
    }

    
    func animateTimeToButton() {
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.timeToButton.layer.backgroundColor = UIColor(named: self.currentStatus ? "stopColor" : "startColor")?.cgColor
        }, completion: nil)
    }
    
    @objc func updatePendingTime() {
        var tmpNextNotificationDate = UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.object(forKey: "nextNotificationDate") as? Date
        if tmpNextNotificationDate != nil {
            let now = Date()
            if tmpNextNotificationDate! < now {
                let lastNotificacionInterval = (UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.double(forKey: "currentTimeInterval"))!
                while tmpNextNotificationDate! < now {
                    tmpNextNotificationDate = tmpNextNotificationDate!.addingTimeInterval(lastNotificacionInterval)
                }
                //nextNotificationDate = tmpNextNotificationDate
            }
            let components = Calendar.current.dateComponents([.hour, .minute, .second], from: now, to: tmpNextNotificationDate!)
            countDownLabel.text = "\(String(format: "%02d", components.minute ?? "00")):\(String(format: "%02d", components.second ?? "00"))"
        } else {
            print("Next Notification Date is nil")
        }
    }
    
    //MARK: - DataPicker delegates
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 0:
            currentInterval = intervals[row].timeInterval
        case 1:
            currentSound = row
            if previewSound { previewSoundMethod() }
        default:
            print("Unrecognized pickerView with tag \(pickerView.tag), event didSelectRow")
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0:
            return intervals.count
        case 1:
            return sounds.count
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 0:
            return intervals[row].title
        case 1:
            return sounds[row]
        default:
            return "Unrecognized picker"
        }
    }
    
    //MARK: - Actions
    
    @IBAction func timeToButtonTouchDown(_ sender: UIButton) {
        sender.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
    }
    
    @IBAction func timeToButtonTouchUpOutside(_ sender: UIButton) {
        sender.transform = CGAffineTransform.identity
    }
    
    @IBAction func timeToButtonPressed(_ sender: UIButton) {
        sender.transform = CGAffineTransform.identity
        if currentStatus {
            currentStatus = false
        } else {
            scheduleNotification()
        }
    }
    
    @IBAction func restrictToLocationValueChanged(_ sender: UISwitch) {
        self.restrictToCurrentLocation = sender.isOn
    }

    @IBAction func restartCountdownWhenMoving(_ sender: UISwitch) {
        self.restartCountdownWhenMoving = sender.isOn
    }

    @IBAction func previewSoundValueChanged(_ sender: UISwitch) {
        self.previewSound = sender.isOn
    }
    
    //MARK: - Notifications scheduller
    
    func showNotificationStatus() {
        var displayString = "Current Pending Notifications is "
        UNUserNotificationCenter.current().getPendingNotificationRequests {
            (requests) in
            displayString += "count \(requests.count)\t"
            for request in requests{
                displayString += request.identifier + "\t"
            }
            print(displayString)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        switch response.actionIdentifier {
        case "Restart":
            print("Restart")
        case "Finish":
            print("Finish")
            currentStatus = false
        default:
            print("default")
        }
        completionHandler()
    }
    
    func scheduleNotification() {
        
        let currentSelectedInterval: TimeInterval = intervals[intervalTimer.selectedRow(inComponent: 0)].timeInterval
        let lastNotificationInterval: TimeInterval = intervals[intervalTimer.selectedRow(inComponent: 0)].timeInterval
        let soundName: String = "\(sounds[currentSound]).wav"
        
        let centre = UNUserNotificationCenter.current()
        centre.getNotificationSettings { (settings) in
            if settings.authorizationStatus != UNAuthorizationStatus.authorized {
                self.showNotificationsHelpViewController()
            } else {
                print("Notifications Authorised")
                let content = UNMutableNotificationContent()
                content.title = NSString.localizedUserNotificationString(forKey: "Time To Do", arguments: nil)
                content.body = NSString.localizedUserNotificationString(forKey: "Something diferent", arguments: nil)
                content.categoryIdentifier = "Category"
                if self.currentSound == 0 {
                    content.sound = UNNotificationSound.default()
                } else {
                    content.sound = UNNotificationSound(named: soundName)
                }
                
                // Schedule the notification.
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: currentSelectedInterval, repeats: true)
                self.nextNotificationDate = trigger.nextTriggerDate()
                let request = UNNotificationRequest(identifier: "TimeToDo", content: content, trigger: trigger)
                let center = UNUserNotificationCenter.current()
                let finishAction = UNNotificationAction.init(identifier: "Finish", title: "Finish", options: UNNotificationActionOptions.foreground)
                let categories = UNNotificationCategory.init(identifier: "Category", actions: [finishAction], intentIdentifiers: [], options: [])
                centre.setNotificationCategories([categories])
                
                center.add(request) { (error : Error?) in
                    if let theError = error {
                        print("Error: \(theError.localizedDescription)")
                        let alertController = UIAlertController(title: "Time To Notifications", message: "Something went wrong and notification could not be created, sorry.\n\(theError.localizedDescription)", preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(OKAction)
                        DispatchQueue.main.async {self.present(alertController, animated: true, completion:nil)}
                    } else {
                        print("Notification scheduled")
                        DispatchQueue.main.async {self.currentStatus = true}
                        UserDefaults(suiteName: "group.es.365d.Time-To-Do")!.set(lastNotificationInterval, forKey: "lastNotificationInterval")
                    }
                }
            }
        }
    }
}


