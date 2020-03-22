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

class AccelerometerInterfaceController: WKInterfaceController {
    
    let motionManager = CMMotionManager()
    var timer: Timer!
    var showNotification = true;
    var session: HKWorkoutSession? // = HKWorkoutSession()
    //var currentWorkoutSession: HKWorkoutSession?
    var isWorkoutRunning = false
    
    @IBOutlet weak var acceleration_x: WKInterfaceLabel!
    @IBOutlet weak var acceleration_y: WKInterfaceLabel!
    @IBOutlet weak var acceleration_z: WKInterfaceLabel!
    
    func showAlert() {
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
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        motionManager.startAccelerometerUpdates()
        timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(AccelerometerInterfaceController.getAccelerometerData), userInfo: nil, repeats: true)

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
    
    @objc func getAccelerometerData() {
        if let accelerometerData = motionManager.accelerometerData {
            let acc_x = accelerometerData.acceleration.x
            let acc_y = accelerometerData.acceleration.y
            let acc_z = accelerometerData.acceleration.z
            
            acceleration_x.setText(String(acc_x))
            acceleration_y.setText(String(acc_y))
            acceleration_z.setText(String(acc_z))
            
            //if(acc_x < -0.85 && acc_y > 0.05){ //&& abs(acc_z) < 0.10){
            //if(acc_x < -0.5 && acc_y > 0.05){ //&& abs(acc_z) < 0.10){
            //if(acc_x < -0.2 && acc_y > 0.05){ //&& abs(acc_z) < 0.10){
            if(acc_x < -0.8 && acc_y > -0.1 ){ //&& acc_z > -0.6){ //&& abs(acc_z) < 0.10){
                //WKInterfaceDevice.current().play(.click)
                WKInterfaceDevice.current().play(.notification)
                if(showNotification){
                    //WKInterfaceDevice.current().play(.notification)
                    showAlert()
                    showNotification = false
                }
            } else {
                //WKInterfaceDevice.current().play(.stop)
                showNotification = true
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
    
    
    
    @IBAction func toggleWorkout(_ value: Bool) {
        if !value {
            session!.end()
            isWorkoutRunning = false
        } else {
            // Begin workout.
            isWorkoutRunning = true
            
            // Clear the local Active Energy Burned quantity when beginning a workout session.
            
            // An indoor walk workout session. There are other activity and location types available to you.
            let configuration = HKWorkoutConfiguration()
            let healthStore = HKHealthStore()
            
            do {
                session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
                session!.startActivity(with: Date())
            } catch {
                dismiss()
                return
            }
        
        }
    }
}