//
//  ViewController.swift
//  Time To
//
//  Created by Antonio Carranza on 30/10/17.
//  Copyright © 2017 Antonio Carranza. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UIViewController, UNUserNotificationCenterDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var intervalTimer: UIDatePicker!
    @IBOutlet weak var soundSelector: UIPickerView!
    @IBOutlet weak var timeToButton: UIButton!
    
    var timer = Timer()
    var sounds = ["Default","Lorry","Fish"]
    
    var currentSoundSelected: String = "Lorry" //TODO: Cargar de UserDefaults
    var currentStatus: Bool = (UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.bool(forKey: "currentStatus"))! {
        didSet {
            print("currentStatus didSet to \(currentStatus)")
            UserDefaults(suiteName: "group.es.365d.Time-To-Do")!.set(currentStatus, forKey: "currentStatus")
            if currentStatus {
                //timeToButton.setTitle("Stop", for: .normal)
                let buttonStopImage = UIImage(named: "stop.png")
                timeToButton.setImage(buttonStopImage, for: .normal)
                scheduleNotification()
            } else {
                let buttonStartImage = UIImage(named: "start.png")
                timeToButton.setImage(buttonStartImage, for: .normal)
                //timeToButton.setTitle("Time To", for: .normal)
                lastNotificationTimeSet = "Nothing scheduled"
                //TODO: Cancelar la notificación
                //      Habrá que sacarlo a una funcion
            }
        }
    }
    
    // Hora que aparecerá en el widget de la proxima notificación prevista.
    var lastNotificationTimeSet: String? {
        didSet {
            print("lastNotificationTimeSet didSet to: \(lastNotificationTimeSet!)")
            UserDefaults(suiteName: "group.es.365d.Time-To-Do")!.set(lastNotificationTimeSet, forKey: "NextNotificationTime")
        }
    }

    //MARK: - Application lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        UNUserNotificationCenter.current().delegate = self
        
        if let existLastNotificationTimeSet = UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.string(forKey: "NextNotificationTime") {
            lastNotificationTimeSet = existLastNotificationTimeSet
        } else {
            lastNotificationTimeSet = "Nothing scheduled"
            currentStatus = false
        }
        
        //UserDefaults(suiteName: "group.es.365d.Time-To-Do")!.set(lastNotificationTimeSet, forKey: "NextNotificationTime")
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(setInitialPickersValues), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: .commonModes)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - DataPicker delegates
    
    @IBAction func intervalChanged(_ sender: UIDatePicker) {
        print("intervalChanged: \(sender.countDownDuration)")
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 1:
            currentSoundSelected = sounds[row]
            print("Sound Selected \(currentSoundSelected)")
        default:
            print("Nothing to do...")
            
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
            return "Nothing"
        }
    }
    
    @objc func setInitialPickersValues() {
        
        //Set the CountdownTimer (intervalTimer) value to 1 hour
        //TODO: Should read from UserDefaults
        
        var c = DateComponents()
        
        c.year = 2017
        c.month = 8
        c.day = 31
        c.hour = 1
        c.minute = 0
        
        if let intervalDate = Calendar(identifier: .gregorian).date(from: c) {
            self.intervalTimer.setDate(intervalDate, animated: true)
        }
        
        //Set the Sound for Notification
        //TODO: Should read from UserDefaults
        self.soundSelector.selectRow(1, inComponent: 0, animated: true)
        
    }

    
    
    
    //MARK: - Actions
    
    @IBAction func timeToButtonPressed(_ sender: UIButton) {
        currentStatus = !currentStatus
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
            //TODO: Cambiar el titulo del boton (esto debiese ser una funcion y no cambiarlo en 2-3 sitios)
            //      Además debiera restablecer los valores del widget y demas
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
            } else {
                print("Notifications Authorised")
                let content = UNMutableNotificationContent()
                content.title = NSString.localizedUserNotificationString(forKey: "Time To Do", arguments: nil)
                content.body = NSString.localizedUserNotificationString(forKey: "Something diferent", arguments: nil)
                content.categoryIdentifier = "Category"
                content.sound = UNNotificationSound(named: "\(self.currentSoundSelected).wav")
                //content.sound = UNNotificationSound.default()
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: currentSelectedInterval, repeats: false)
                
                // Share Data with extension trhough Userfeaults shared group "group.es.365d.TimeTo"
                let timeFormatter = DateFormatter()
                timeFormatter.dateStyle = .full
                timeFormatter.timeStyle = .medium
                timeFormatter.timeZone = .current
                timeFormatter.locale = Locale(identifier: "es_ES")
                self.lastNotificationTimeSet = timeFormatter.string(from: trigger.nextTriggerDate()!)
                
                UserDefaults(suiteName: "group.es.365d.Time-To-Do")!.set(self.lastNotificationTimeSet, forKey: "NextNotificationTime")
                
                // Schedule the notification.
                let request = UNNotificationRequest(identifier: "TimeToDo", content: content, trigger: trigger)
                let center = UNUserNotificationCenter.current()
                let continueAction = UNNotificationAction.init(identifier: "Restart", title: "Restart", options: UNNotificationActionOptions())
                let finishAction = UNNotificationAction.init(identifier: "Finish", title: "Finish", options: UNNotificationActionOptions.foreground)
                let categories = UNNotificationCategory.init(identifier: "Category", actions: [continueAction, finishAction], intentIdentifiers: [], options: [])
                
                centre.setNotificationCategories([categories])
                //center.add(request, withCompletionHandler: nil)
                
                print(Date())
                center.add(request) { (error : Error?) in
                    if let theError = error {
                        print(theError.localizedDescription)
                    } else {
                        print("\(Date()) - Notificacion programada")
                    }
                }
                
            }
        }
    }
    
}

