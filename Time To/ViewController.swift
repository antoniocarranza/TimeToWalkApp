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

class ViewController: UIViewController, UNUserNotificationCenterDelegate, UIPickerViewDelegate, UIPickerViewDataSource, CLLocationManagerDelegate {

    //MARK: - Outlets and Variables
    
    @IBOutlet weak var intervalTimer: UIDatePicker!
    @IBOutlet weak var soundSelector: UIPickerView!
    @IBOutlet weak var timeToButton: UIButton!
    @IBOutlet weak var restrictToCurrentLocationSwitch: UISwitch!
    @IBOutlet weak var previewSoundSwitch: UISwitch!
    
    var timer = Timer()
    var statusTimer = Timer()
    var sounds = ["Default","Lorry","Phone","Hyena"]
    var player: AVAudioPlayer?
    var locationManager:CLLocationManager!
    var locationCounter: Int = 0
    
    var restrictToCurrentLocation: Bool = (UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.bool(forKey: "restrictToCurrentLocation"))! {
        didSet {
            print("Restrict to current location saved to \(restrictToCurrentLocation)")
            UserDefaults(suiteName: "group.es.365d.Time-To-Do")!.set(restrictToCurrentLocation, forKey: "restrictToCurrentLocation")
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
            if currentStatus {
                let buttonStopImage = UIImage(named: "Stop.png")
                self.timeToButton.setImage(buttonStopImage, for: .normal)
                locationManager.startMonitoringSignificantLocationChanges()
                } else {
                    let buttonStartImage = UIImage(named: "Play")
                    self.timeToButton.setImage(buttonStartImage, for: .normal)
                    self.nextNotificationDate = nil
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    locationManager.stopMonitoringSignificantLocationChanges()
                    self.locationCounter = 0
                }
            }
        }
    
    // Hora que aparecerá en el widget de la proxima notificación prevista.
    var nextNotificationDate: Date? = UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.object(forKey: "nextNotificationDate") as? Date {
        didSet {
            print("nextNotificationDate saved to \(nextNotificationDate?.description ?? "not set or set to nil")")
            UserDefaults(suiteName: "group.es.365d.Time-To-Do")!.set(nextNotificationDate, forKey: "nextNotificationDate")
        }
    }
    
    //MARK: - Application lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        UNUserNotificationCenter.current().delegate = self
        
        // Update controls to saved status
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(setInitialControlsValues), userInfo: nil, repeats: false)
        statusTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(checkStatus), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .commonModes)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("Current Status \(currentStatus)")
        print("Current Interval \(currentInterval)")
        print("Current Sound \(currentSound)")
        print("Next Notification Date \(nextNotificationDate?.description ?? "not set or nil")")
        print("Restrict to current location status is \(restrictToCurrentLocation)")
        print("Preview Sound status is \(previewSound)")
        determineMyCurrentLocation()
        checkStatus()
    }
    
    func determineMyCurrentLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestAlwaysAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.
        
        // manager.stopUpdatingLocation()
        let string = "user latitude = \(userLocation.coordinate.latitude)\nuser longitude = \(userLocation.coordinate.longitude)"
        print(string)

        if self.currentStatus && self.locationCounter > 0 { self.currentStatus = false }
        
        self.locationCounter += 1
        
//        let alert = UIAlertController(title: "Alert", message: string, preferredStyle: UIAlertControllerStyle.alert)
//        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
//        self.present(alert, animated: true, completion: nil)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func checkStatus() {
        let now = Date()
        let newStatus = (UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.bool(forKey: "currentStatus"))!

        //print("Checking: current status \(currentStatus), new status \(newStatus), current date \(now), scheduled date \(nextNotificationDate?.description ?? "Not set or set to nil")")
        
        if newStatus != currentStatus {
            currentStatus = newStatus
        }
        
        showNotificationStatus()
        
        if nextNotificationDate != nil {
            let components = Calendar.current.dateComponents([.hour, .minute, .second], from: now, to: nextNotificationDate!)
            let timetoNotification = "\(String(format: "%02d", components.minute ?? "00")):\(String(format: "%02d", components.second ?? "00"))"
            print("Time no next notification is \(timetoNotification)")
        }
    }
    
    //MARK: - DataPicker delegates
    @IBAction func intervalChanged(_ sender: UIDatePicker) {
        currentInterval = intervalTimer.countDownDuration
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
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
        case 1:
            return sounds.count
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 1:
            return sounds[row]
        default:
            return "Unrecognized picker"
        }
    }
    
    @objc func setInitialControlsValues() {
        
        //Set the Interval Picker to last saved value or to 1 hour
        if currentInterval == 0 {currentInterval = 3600}
        
        var c = DateComponents()
        
        c.year = Calendar.current.component(.year, from: Date())
        c.month = Calendar.current.component(.month, from: Date())
        c.day = Calendar.current.component(.day, from: Date())
        c.hour = 0
        c.minute = 0
        c.second = Int(currentInterval)
        
        if let intervalDate = Calendar(identifier: .gregorian).date(from: c) {
            self.intervalTimer.setDate(intervalDate, animated: true)
        }
        
        //Set the Sound selected for Notification
        self.soundSelector.selectRow(currentSound, inComponent: 0, animated: true)
        
        //Set the switches Values
        self.restrictToCurrentLocationSwitch.setOn(restrictToCurrentLocation, animated: true)
        self.previewSoundSwitch.setOn(previewSound, animated: true)
    }
    
    func previewSoundMethod() {
        
        if previewSound {
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
    }
    
    //MARK: - Actions
    
    @IBAction func timeToButtonPressed(_ sender: UIButton) {
        if currentStatus {
            currentStatus = false
        } else {
            scheduleNotification()
        }
    }
    
    @IBAction func restrictToLocationValueChanged(_ sender: UISwitch) {
        self.restrictToCurrentLocation = sender.isOn
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
        
//        let lastNotificacionInterval = (UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.double(forKey: "currentTimeInterval"))!
        completionHandler([.alert,.sound, .badge])
        
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        switch response.actionIdentifier {
        case "Restart":
            //completionHandler()
            print("Restart")
        case "Finish":
            print("Finish")
            currentStatus = false
        default:
            //completionHandler()
            print("default")
            //currentStatus = true
        }
        //completionHandler()
    }
    
    func scheduleNotification() {
        
        let currentSelectedInterval: TimeInterval = intervalTimer.countDownDuration
        let lastNotificationInterval: TimeInterval = intervalTimer.countDownDuration
        let soundName: String = "\(sounds[currentSound]).wav"
        
        let centre = UNUserNotificationCenter.current()
        centre.getNotificationSettings { (settings) in
            if settings.authorizationStatus != UNAuthorizationStatus.authorized {
                print("Notifications Not Authorised for this App")
                let alertController = UIAlertController(title: "Time To Notifications", message: "Check that notifications are enabled at Preferences > Notifications for Time To App", preferredStyle: .alert)
                let OkAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertController.addAction(OkAction)
                DispatchQueue.main.async {self.present(alertController, animated: true, completion:nil)}
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
                //let continueAction = UNNotificationAction.init(identifier: "Restart", title: "Restart", options: UNNotificationActionOptions())
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

