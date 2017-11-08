//
//  TodayViewController.swift
//  Today
//
//  Created by Antonio Carranza on 30/10/17.
//  Copyright © 2017 Antonio Carranza. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var widgetLabel: UILabel!
    @IBOutlet weak var pendingTimeLabel: UILabel!
    
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
        updateWidget()
        
        
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
            updateWidget()
            updatePendingTime()  //TODO: ¿Es necesario?
        }
        completionHandler(NCUpdateResult.newData)
    }
    
    //MARK: - Widget Update
    
    @objc func updateWidget() {
        if let nextNotificationDate = UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.object(forKey: "nextNotificationDate") as? Date {
            self.widgetLabel.text = formatDate(dateToFormat: nextNotificationDate)
            print("Next Notification Date is set to \(nextNotificationDate.description)")
        } else {
            print("Next Notification Date not set or set to nil")
        }
    }
    
    @objc func updatePendingTime() {
        
        if let nextNotificationDate = UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.object(forKey: "nextNotificationDate") as? Date {
            self.widgetLabel.text = formatDate(dateToFormat: nextNotificationDate)
            let now = Date()
            if nextNotificationDate > now {
                let components = Calendar.current.dateComponents([.hour, .minute, .second], from: now, to: nextNotificationDate)
                pendingTimeLabel.text = "\(String(format: "%02d", components.minute ?? "00")):\(String(format: "%02d", components.second ?? "00"))"
            } else {
                if currentStatus == true {
                    currentStatus = false
                }
            }
        }
    }
    
    func formatDate(dateToFormat: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dateToFormat)
    }
}
