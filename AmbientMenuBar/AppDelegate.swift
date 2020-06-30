//
//  AppDelegate.swift
//  AmbientMenuBar
//
//  Created by fuku on 2020/06/26.
//  Copyright © 2020 yfuku. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
    
    @IBOutlet weak var menu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    let apiUrl = "https://ambidata.io/api/v2/channels/XXXXX/data?readKey=XXXXXXXXXXX&n=1"
    let dataFieldId = "d1"
    let highThreshold = 1000
    let lowThreshold = 800
    let blinkCount = 10
    let blinnkInterval = 0.5
    let timeInterval = 60.0
    let notificationTitle = "CO2濃度が高くなっています"
    let notificationSubtitle = "換気をしてください！"
    var isHighPpm = false
    

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.statusItem.button?.title = "---ppm"
        self.statusItem.menu = menu
        
        let lastUpdateItem = NSMenuItem()
        lastUpdateItem.title = ""
        menu.addItem(lastUpdateItem)

        let quitItem = NSMenuItem()
        quitItem.title = "Quit"
        quitItem.action = #selector(AppDelegate.quit(_:))
        menu.addItem(quitItem)
        
        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { (timer) in
            let url = URL(string: self.apiUrl)!
            let request = URLRequest(url: url)
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let data = data else { return }
                do {
                    let object = try JSONSerialization.jsonObject(with: data, options: [])
                    let arr = object as! NSArray
                    let firstData = arr[0] as! NSDictionary
                    let ppm = firstData[self.dataFieldId] as! Int
                    let created = firstData["created"] as! String

                    print(String(ppm) + " : " + created)

                    DispatchQueue.main.sync {
                        self.statusItem.button?.title = String(ppm) + "ppm"
                        lastUpdateItem.title = created
                    }
                    
                    if self.isHighPpm == false && ppm >= self.highThreshold {
                        self.isHighPpm = true
                        
                        NSUserNotificationCenter.default.delegate = self
                        let notification = NSUserNotification()
                        notification.title = self.notificationTitle
                        notification.subtitle = self.notificationSubtitle
                        notification.contentImage =  NSImage(named: "blue")
                        NSUserNotificationCenter.default.deliver(notification)
                        
                        for _ in 1...self.blinkCount {
                            DispatchQueue.main.sync {self.statusItem.button?.highlight(true)}
                            Thread.sleep(forTimeInterval: self.blinnkInterval)
                            DispatchQueue.main.sync {self.statusItem.button?.highlight(false)}
                            Thread.sleep(forTimeInterval: self.blinnkInterval)
                        }
                        DispatchQueue.main.sync {self.statusItem.button?.highlight(true)}
                    } else if ppm <= self.lowThreshold {
                        self.isHighPpm = false
                        DispatchQueue.main.sync {self.statusItem.button?.highlight(false)}
                    }
                    
                } catch let error {
                    print(error)
                }
            }
            task.resume()
        })
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc func quit(_ sender: Any){
        NSApplication.shared.terminate(self)
    }
}

