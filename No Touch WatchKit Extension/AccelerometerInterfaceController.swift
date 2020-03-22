//
//  AccelerometerInterfaceController.swift
//  No Touchy
//
//  Created by Lukas Wegryn on 3/21/20.
//  Copyright © 2020 Pensive Seucirty. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion
import UserNotifications
import HealthKit
import CoreFoundation

class AccelerometerInterfaceController: WKInterfaceController, WKExtendedRuntimeSessionDelegate {
    let motionManager = CMMotionManager()
    var timer: Timer!
    var nTimer: Timer!
    var showNotification = true;
    var session: HKWorkoutSession?
    var isWorkoutRunning = false
    
    var currentAlert = ""
    
    var selfCareSession: WKExtendedRuntimeSession?
    var isSelfCareRunning = false
    
    @IBOutlet weak var acceleration_x: WKInterfaceLabel!
    @IBOutlet weak var acceleration_y: WKInterfaceLabel!
    @IBOutlet weak var acceleration_z: WKInterfaceLabel!
    @IBOutlet weak var enableSwitch: WKInterfaceSwitch!
    @IBOutlet weak var diagnosticGroup: WKInterfaceGroup!
    
    
    
    /*var thresholds = ["lr": [-0.8, -0.1],
    "ll": [],
    "rl": [-0.8,],
    "rr": []]*/
    
    @objc func removeAlert(uuid: String) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [uuid])
    }
    
    func showAlert() -> String {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        let sound = UNNotificationSound.default
        let uuidString = UUID().uuidString
        content.title = "No Touchy"
        content.body = "Please Don't Touch Your Face!"
        content.sound = sound
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: (0.1), repeats: false)
        let request = UNNotificationRequest(identifier: uuidString,
                    content: content, trigger: trigger)
        center.add(request)
        return uuidString
    }
    
    func showSessionEndingAlert(){
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        let sound = UNNotificationSound.default
        let uuidString = UUID().uuidString
        content.title = "No Touch"
        content.body = "Your No Touch session is ending. Please re-enable in the app if necessary."
        content.sound = sound
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: (0.1), repeats: false)
        let request = UNNotificationRequest(identifier: uuidString,
                    content: content, trigger: trigger)
        center.add(request)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        motionManager.startAccelerometerUpdates()
        timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(AccelerometerInterfaceController.getAccelerometerData), userInfo: nil, repeats: true)
        /*timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(AccelerometerInterfaceController.removeAlerts), userInfo: nil, repeats: true)*/

        acceleration_x.setText(String(1.0))
        acceleration_y.setText(String(1.0))
        acceleration_z.setText(String(1.0))

        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        //NOTIFICATION CODE
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            
            if let error = error {
                // Handle the error here.
            }
            // Enable or disable features based on the authorization.
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func isFaceTouching(acceleration: CMAcceleration) -> Bool{
        //Wrist   |    Crown
        // L      |      R         acc_x < -0.8 && acc_y > -0.1
        // R      |      L         acc_x < -0.8 && acc_y < -0.1
        // L      |      L
        // R      |      R
        
        //let x_thresh = 0.8
        let x_thresh = 0.87
        let y_thresh = 0.1
        let wrist = WKInterfaceDevice.current().wristLocation
        let crown = WKInterfaceDevice.current().crownOrientation
        let acc_x = acceleration.x
        let acc_y = acceleration.y
        
        if (wrist == .left && crown == .right){
            if (acc_x < -x_thresh && acc_y > -y_thresh){
                return true
            }
                return false
        } else if (wrist == .right && crown == .left){
            if (acc_x < -x_thresh && acc_y < -y_thresh){
                return true
            }
                return false
        } else if (wrist == .left && crown == .left){
            if (acc_x > x_thresh && acc_y < -y_thresh){
                return true
            }
                return false
        } else if (wrist == .right && crown == .right){
            if (acc_x > x_thresh && acc_y > y_thresh){
                return true
            }
                return false
        }
        return false
    
    }
    
    @objc func getAccelerometerData() {
        if let accelerometerData = motionManager.accelerometerData {
            let acc_x = accelerometerData.acceleration.x
            let acc_y = accelerometerData.acceleration.y
            let acc_z = accelerometerData.acceleration.z
            
            acceleration_x.setText(String(acc_x))
            acceleration_y.setText(String(acc_y))
            acceleration_z.setText(String(acc_z))
        
            if(isFaceTouching(acceleration: accelerometerData.acceleration)){
                //WKInterfaceDevice.current().play(.click)
                WKInterfaceDevice.current().play(.notification)
                if(showNotification){
                    //WKInterfaceDevice.current().play(.notification)
                    //removeAlerts()
                    if(currentAlert != ""){
                        removeAlert(uuid: currentAlert)
                    }
                    currentAlert = showAlert()
                    //timeSinceLastFacetouchStart = DispatchTime.now()
                    showNotification = false
                }
            } else {
                //WKInterfaceDevice.current().play(.stop)
                showNotification = true
                //let timeNow = DispatchTime.now().uptimeNanoseconds
                //let nanoTime = timeSinceLastFacetouchStart.uptimeNanoseconds - timeNow
                //let secondsElapsed = Double(nanoTime) / 1_000_000_000
                //if(secondsElapsed > 5 && secondsElapsed < 10){
                  //  removeAlerts()
                //}
            }

        }
        /*if let gyroData = motionManager.gyroData {
            print(gyroData)
        }
        if let magnetometerData = motionManager.magnetometerData {
            print(magnetometerData)
        }
        if let deviceMotion = motionManager.deviceMotion {
            print(deviceMotion)
        }*/
    }
    
    
    @IBAction func toggleDiagnostic(_ value: Bool) {
            if !value {
                diagnosticGroup.setHidden(true)
            } else {
                diagnosticGroup.setHidden(false)
            }
        }

    @IBAction func toggleSession(_ value: Bool) {
        selfCareSession = WKExtendedRuntimeSession()
        if !value {
            selfCareSession!.invalidate()
            isSelfCareRunning = false
        } else {
            // Begin session.
            isSelfCareRunning = true
            selfCareSession!.start()
        
        }
    }


    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        // Track when your session starts.
    }

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        // Finish and clean up any tasks before the session ends.
        showSessionEndingAlert()
    }
        
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        // Track when your session ends.
        // Also handle errors here.
        enableSwitch.setOn(false)
    }
    
    /*@IBAction func toggleWorkout(_ value: Bool) {
        if !value {
            session!.end()
            isWorkoutRunning = false
        } else {
            // Begin workout.
            isWorkoutRunning = true
            
            // Clear the local Active Energy Burned quantity when beginning a workout session.
            
            // An indoor walk workout session. There are other activity and location types available to you.
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .mindAndBody
            let healthStore = HKHealthStore()
            
            do {
                session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
                session!.startActivity(with: Date())
            } catch {
                dismiss()
                return
            }
        
        }
    }*/
}
