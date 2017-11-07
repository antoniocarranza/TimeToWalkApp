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

class ViewController: UIViewController, UNUserNotificationCenterDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var intervalTimer: UIDatePicker!
    @IBOutlet weak var soundSelector: UIPickerView!
    @IBOutlet weak var timeToButton: UIButton!
    
    var timer = Timer()
    var sounds = ["Default","Lorry","Airplane","Phone","Hyena"]
    var player: AVAudioPlayer?
    
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
                } else {
                let buttonStartImage = UIImage(named: "Play")
                    self.timeToButton.setImage(buttonStartImage, for: .normal)
                }
            }
        }
    
    // Hora que aparecerá en el widget de la proxima notificación prevista.
    var nextNotificationDate: Date? = UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.object(forKey: "nextNotificationDate") as? Date {
        didSet {
            print("nextNotificationDate saved to \(nextNotificationDate!.description)")
            UserDefaults(suiteName: "group.es.365d.Time-To-Do")!.set(nextNotificationDate, forKey: "nextNotificationDate")
        }
    }
    //MARK: - Application lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        UNUserNotificationCenter.current().delegate = self
        
        // Update controls to saved status
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(setInitialPickersValues), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: .commonModes)
        
        // Update Start Button to current status
        currentStatus = (UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.bool(forKey: "currentStatus"))!
        
        // Show initial values at console
        print("View Did Load!")
        print("Current Status \(currentStatus)")
        print("Current Interval \(currentInterval)")
        print("Current Sound \(currentSound)")
        print("Next Notification Date \(nextNotificationDate?.description ?? "not set or nil")")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - DataPicker delegates
    @IBAction func intervalChanged(_ sender: UIDatePicker) {
        currentInterval = intervalTimer.countDownDuration
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 1:
            currentSound = row
            previewSound()
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
    
    @objc func setInitialPickersValues() {
        
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
    }
    
    func previewSound() {
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
    
    //MARK: - Actions
    
    @IBAction func timeToButtonPressed(_ sender: UIButton) {
        //TODO: Intentar la logica aqui y en funcion del resultado cambiar el status.
        
        if currentStatus {
            //TODO: Delete Notifications
            currentStatus = false
        } else {
            scheduleNotification()
        }
    }
    
    //MARK: - Notifications scheduller
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Test: \(response.notification.request.identifier)")
        //currentAction = response.actionIdentifier
        
        switch response.actionIdentifier {
        case "Complete":
            completionHandler()
            currentStatus = true
        case "Finish":
            //TODO: Eliminar la notificacion?
            currentStatus = false
            completionHandler()
        default:
            completionHandler()
            currentStatus = true
        }
        completionHandler()
    }
    
    func scheduleNotification() {
        
        let currentSelectedInterval: TimeInterval = intervalTimer.countDownDuration
        
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
                    content.sound = UNNotificationSound(named: "\(self.currentSound).wav")
                }
                
                // Schedule the notification.
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: currentSelectedInterval, repeats: false)
                self.nextNotificationDate = trigger.nextTriggerDate()
                let request = UNNotificationRequest(identifier: "TimeToDo", content: content, trigger: trigger)
                let center = UNUserNotificationCenter.current()
                let continueAction = UNNotificationAction.init(identifier: "Restart", title: "Restart", options: UNNotificationActionOptions())
                let finishAction = UNNotificationAction.init(identifier: "Finish", title: "Finish", options: UNNotificationActionOptions.foreground)
                let categories = UNNotificationCategory.init(identifier: "Category", actions: [continueAction, finishAction], intentIdentifiers: [], options: [])
                centre.setNotificationCategories([categories])
                
                center.add(request) { (error : Error?) in
                    if let theError = error {
                        print("Error: \(theError.localizedDescription)")
                        let alertController = UIAlertController(title: "Time To Notifications", message: "Something went wrong and notification could not be created, sorry.\n\(theError.localizedDescription)", preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(OKAction)
                        DispatchQueue.main.async {self.present(alertController, animated: true, completion:nil)}
                    } else {
                        print("Notifycation scheduled")
                        DispatchQueue.main.async {self.currentStatus = true}
                    }
                }
            }
        }
    }
}

