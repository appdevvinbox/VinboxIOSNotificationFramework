//
//  Vinmax.swift
//  VinboxIOSNotificationFramework
//
//  Created by BarrelCoders on 16/11/22.
//

import Foundation
import FirebaseCore
import FirebaseMessaging

public struct DecodableType: Decodable { let response: String }

public class Vinmax: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    public func initialize (application: UIApplication){
        
        FirebaseApp.prepareForInterfaceBuilder()
                       
        let options = FirebaseOptions(googleAppID: Configuration.GOOGLE_APP_ID,
                                      gcmSenderID: Configuration.GCM_SENDER_ID)
        options.projectID = Configuration.PROJECT_ID
        options.apiKey = Configuration.API_KEY
        options.databaseURL = Configuration.DATABASE_URL

        FirebaseApp.configure(options: options)
        
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
           options: authOptions,
           completionHandler: { _, _ in }
        )
       
        application.registerForRemoteNotifications()
    }
    
    public func postToken(token: String) {
        let url = URL(string: Configuration.API_URL)
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
         
        let postString = String(format:"token=%@&platform=iOS", token)
        request.httpBody = postString.data(using: String.Encoding.utf8);
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("postToken: failure \(error)")
                    return
                }
         
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    print("postToken: success:\n \(dataString)")
                }
        }
        task.resume()
    }
        
    // Receive displayed notifications for iOS 10 devices.
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler([.banner, .sound])
    }
    

    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
      let userNotification = response.notification.request.content.userInfo

      // With swizzling disabled you must let Messaging know about the message, for Analytics
      // Messaging.messaging().appDidReceiveMessage(userInfo)

      print(userNotification)
    }
    
     public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
       print("Received FCM Token \(fcmToken!)")
         
       let dataDict: [String: String] = ["token": fcmToken ?? ""]
       NotificationCenter.default.post(
         name: Notification.Name("FCMToken"),
         object: nil,
         userInfo: dataDict
       )
         
       self.postToken(token: fcmToken!);
     }
    
    public func didReceiveRemoteNotification(userNotification: [AnyHashable: Any])async
    -> UIBackgroundFetchResult {
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        return UIBackgroundFetchResult.newData
    }
    
    public func didRegisterForRemoteNotificationsWithDeviceToken(deviceToken: Data){
        print("App successfully register for Remote Notification with device_token")
        Messaging.messaging().setAPNSToken(deviceToken, type: .unknown)
    }
}

