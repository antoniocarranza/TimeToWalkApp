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
            if currentStatus {
                timer.fire()
            } else {
                timer.invalidate()
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
            UserDefaults(suiteName: "group.es.365d.Time-To-Do")!.set(currentStatus, forKey: "currentStatus")
            updateWidget()
            updatePendingTime()  //TODO: ¿Es necesario?
        }
        completionHandler(NCUpdateResult.newData)
    }
    
    //MARK: - Widget Update
    
    @objc func updateWidget() {
        let nextNotificationTimeString = UserDefaults(suiteName: "group.es.365d.Time-To-Do")?.string(forKey: "NextNotificationTime")
        self.widgetLabel.text = nextNotificationTimeString
    }
    
    @objc func updatePendingTime() {
        if pendingTimeLabel.text == "Pending time -" {
            pendingTimeLabel.text = "Pending time |"
        } else {
            self.pendingTimeLabel.text = "Pending time -"
        }
    }
    
}
