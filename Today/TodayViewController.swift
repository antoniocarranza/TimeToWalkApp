//
//  TodayViewController.swift
//  Today
//
//  Created by Antonio Carranza on 30/10/17.
//  Copyright © 2017 Antonio Carranza. All rights reserved.
//

import UIKit
import NotificationCenter
import UserNotifications

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var widgetLabel: UILabel!
    @IBOutlet weak var pendingTimeLabel: UILabel!
    @IBOutlet weak var lastRestartDateLabel: UILabel!
    @IBOutlet weak var previousDistanceLabel: UILabel!
    
    var timer = Timer()
    var currentStatus: Bool = false {
        didSet {
            print("Status saved to \(currentStatus)")
            UserDefaults(suiteName: "group.es.365d.Time-To-Do")!.set(currentStatus, forKey: "currentStatus")
            if currentStatus {
            } else {
                widgetLabel.text = "Nothing scheduled"
                pendingTimeLabel.text = ""
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


    let widgetUpdateTimeInterval: TimeInterval = 1
    
    //MARK: - Application lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        //timer for update widget every widgetUpdateTimeInterval value
        timer = Timer.scheduledTimer(timeInterval: self.widgetUpdateTimeInterval, target: self, selector: #selector(updatePendingTime), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .commonModes)
        currentStatus = (UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.bool(forKey: "currentStatus"))!
        print("Current Status is set to \(currentStatus)")
        updatePendingTime()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        currentStatus = (UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.bool(forKey: "currentStatus"))!
        if currentStatus {
            //updateWidget() //TODO: ¿Es necesario?
            updatePendingTime()
            completionHandler(NCUpdateResult.newData)
        } else {
            completionHandler(NCUpdateResult.noData)
        }
    }
    
    //MARK: - Widget Update
    
//    @objc func updateWidget() {
//        var tmpNextNotificationDate = UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.object(forKey: "nextNotificationDate") as? Date
//        let tmpLastLocationDate = UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.object(forKey: "nextNotificationDate") as? Date
//        if tmpLastLocationDate != nil { self.lastRestartDateLabel.text = formatDate(dateToFormat: lastLocationDate!) }
//        if tmpNextNotificationDate != nil {
//            self.widgetLabel.text = formatDate(dateToFormat: tmpNextNotificationDate!)
//            print("Next Notification Date is set to \(nextNotificationDate!.description)")
//        } else {
//            print("Next Notification Date not set or set to nil")
//        }
//        showNotificationStatus()
//    }
    
    @objc func updatePendingTime() {
        var tmpNextNotificationDate = UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.object(forKey: "nextNotificationDate") as? Date
        let tmpLastLocationDate = UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.object(forKey: "lastLocationDate") as? Date
        if tmpLastLocationDate != nil { self.lastRestartDateLabel.text = formatDate(dateToFormat: tmpLastLocationDate!, dateStyle: .none, timeStyle: .short) }
        let tmpPreviousDistance = round((UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.double(forKey: "distanceInMetersFromPreviousLocation"))!)
        self.previousDistanceLabel.text = "\(tmpPreviousDistance) mts"
        if tmpNextNotificationDate != nil {
            self.widgetLabel.text = formatDate(dateToFormat: tmpNextNotificationDate!, dateStyle: .medium, timeStyle: .medium)
            let now = Date()
            if tmpNextNotificationDate! < now {
                let lastNotificacionInterval = (UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.double(forKey: "currentTimeInterval"))!
                while tmpNextNotificationDate! < now {
                    tmpNextNotificationDate = tmpNextNotificationDate!.addingTimeInterval(lastNotificacionInterval)
                }
                nextNotificationDate = tmpNextNotificationDate
            }
            let components = Calendar.current.dateComponents([.hour, .minute, .second], from: now, to: tmpNextNotificationDate!)
            pendingTimeLabel.text = "\(String(format: "%02d", components.minute ?? "00")):\(String(format: "%02d", components.second ?? "00"))"
        } else {
            print("Next Notification Date is nil")
        }
        //showNotificationStatus()
    }
    
    func showNotificationStatus() {
        var displayString = "Current Pending Notifications "
        UNUserNotificationCenter.current().getPendingNotificationRequests {
            (requests) in
            displayString += "count \(requests.count)\t"
            for request in requests{
                displayString += request.identifier + "\t"
            }
            print(displayString)
        }
    }
    
    @IBAction func changeSettings(_ sender: UIButton) {
        let url: URL? = URL(string: "setup:")!
        if let appurl = url {
            self.extensionContext!.open(appurl, completionHandler: nil)
        }
    }
    
    func formatDate(dateToFormat: Date, dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: dateToFormat)
    }
}
