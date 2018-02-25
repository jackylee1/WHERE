//
//  MapViewController.swift
//  MySampleApp
//
//  Created by Jingxuan Zhang on 4/24/17.
//  Improved by Yongyi Yang on 1/5/17
//

import UIKit
import GoogleMaps
import os
import AWSMobileHubHelper
import AWSSQS
import AVFoundation

@available(iOS 10.0, *)
class MapViewController: UIViewController, CLLocationManagerDelegate {
    
    var mapView : GMSMapView!
    var locationManager = CLLocationManager()
    var markers = [String: GMSMarker]()
    var timer = Timer()
    var i = 0.001
    var j = 1.0
    var credentialProvider : AWSCognitoCredentialsProvider! = nil
    var awsConfig : AWSServiceConfiguration! = nil
    var mySQS : AWSSQS! = nil
    var myQueueUrl : String! = nil
    var myUsername : String! = nil
    let identityManager = AWSIdentityManager.default()
    var postBuf = [String: String]()
    let queueUrl = "https://sqs.us-east-1.amazonaws.com/ /send_que"
    
    override func loadView() {
        // AWS auth stuffs
        credentialProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "us-east-1:")
        awsConfig = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialProvider)
        AWSServiceManager.default().defaultServiceConfiguration = awsConfig
        mySQS = AWSSQS.default()
        
        // init Google Map
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.isMyLocationEnabled = true
        mapView.settings.scrollGestures = true
        mapView.settings.myLocationButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.compassButton = true
        view = mapView
        
        self.locationManager.delegate = self
        self.locationManager.startUpdatingLocation()
        
        myUsername = identityManager.userName!

        // create queue if not created
        let createQueueReq = AWSSQSCreateQueueRequest()
        print(createQueueReq!)
        createQueueReq?.queueName = identityManager.userName
        
        mySQS.createQueue(createQueueReq!).continueWith{ (task) -> AnyObject! in
            if let error = task.error{
                print(error)
            }
            if let data = task.result {
                self.myQueueUrl = data.queueUrl!
                let reqc = ReqCollector()
                let fetchReq = FetchMsgSendReq(Username: self.myUsername, UserQueue: self.myQueueUrl)
                reqc.append(request: fetchReq.getReq())
                let sendReq = AWSSQSSendMessageRequest()!
                sendReq.messageBody = reqc.getReqText()
                sendReq.queueUrl = self.queueUrl
                self.mySQS.sendMessage(sendReq)
                print("fetch msg req sent")
            }
            else {print("an error here")}
            return nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("-----hey------")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        scheduledTimerWithTimeInterval()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        timer.invalidate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        guard let nav = segue.destination as? UINavigationController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }
        guard let postViewController = nav.topViewController as? PostViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }
        postViewController.username = self.myUsername
        postViewController.queueUrl = self.myQueueUrl
        postViewController.mySQS = self.mySQS
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // Location Manager delegates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last
        
        let camera = GMSCameraPosition.camera(withLatitude: (location?.coordinate.latitude)!, longitude:(location?.coordinate.longitude)!, zoom:14)
        (view as? GMSMapView)?.animate(to: camera)
        
        //Finally stop updating location otherwise it will come again and again in this delegate
        self.locationManager.stopUpdatingLocation()
        
    }
    
    func scheduledTimerWithTimeInterval() {
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: updateCounting(_:))
    }
    
    func updateCounting(_ timer: Timer) {
        os_log("counting...", log: OSLog.default, type: .debug)
        let sendMsgReq = AWSSQSSendMessageRequest()!
        sendMsgReq.queueUrl = queueUrl
        let dic = [["Method": "updateLoc",
                    "Loc" :
                        ["Latitude": locationManager.location?.coordinate.latitude,
                         "Longitude": locationManager.location?.coordinate.longitude],
                    "userQueue" : myQueueUrl,
                    "userId": identityManager.userName!]];
        //print(dic)
        let jsonData = try? JSONSerialization.data(withJSONObject: dic, options: [])
        let jsonText = String(data: jsonData!, encoding: .utf8)
        sendMsgReq.messageBody = jsonText
        mySQS.sendMessage(sendMsgReq)
        pollingQueue()
        
    }
    
    func parseRecvReq(recvReq jsonText: String) {
        let data = jsonText.data(using: .utf8)
        //let parsedDataArray = try? JSONSerialization.jsonObject(with: data!, options: []) as! Array<Any>
        //for dataItem in parsedDataArray! {
        let dataItem = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String: String]
        let parsedItem = dataItem!
        switch (parsedItem["response"] ?? "post") {
        case "updateLoc":
            parseUpdateLocRecvReq(parsedItem)
        case "fetchMsg":
            parseFetchMsgRecvReq(parsedItem)
        default:
            print("This should be the post response")
            parseNewPostRecvReq(parsedItem)
        }
        //}
    }
    
    private func parseNewPostRecvReq(_ data: [String: String]) {
        print(data)
        print(data["Message"]!)
        let rawPostReq = data["Message"]!.data(using: .utf8)
        let parsedPostReq = try? JSONSerialization.jsonObject(with: rawPostReq!, options: []) as! [String: String]
        print("receive a new post")
        parseFetchMsgRecvReq(parsedPostReq!)
    }
    
    private func parseUpdateLocRecvReq(_ data: [String: String]) {
        let rawLocArr = data["Loc"]?.data(using: .utf8)
        let parsedLocArr = try? JSONSerialization.jsonObject(with: rawLocArr!, options: []) as! [[String: Any]]
        for rawLocItem in parsedLocArr! {
            // if user's Loc is null
            if(rawLocItem["Longitude"] is NSNull || rawLocItem["Latitude"] is NSNull){
                print("user is offline")
            }
            // valid Loc
            else{
            let userId = rawLocItem["userId"] as! String
            let longtitude = rawLocItem["Longitude"] as! Double
            let latitude = rawLocItem["Latitude"] as! Double
            print("user \(userId) is at \(longtitude), \(latitude)")
            if let mk = markers[userId] {
                mk.position.latitude = latitude
                mk.position.longitude = longtitude
            } else {
                print("new user found!!!")
                //let loc = CLLocationCoordinate2D(latitude: latitude, longitude: longtitude)
                //let newMarker = GMSMarker(position:loc)
                //newMarker.position = loc
                //newMarker.title = userId;
                //newMarker.map = mapView
                //markers[userId] = newMarker
            }
            // collect those msg that has not been displayed on the map
            if let post = postBuf[userId] {
                print("Found \(userId), set post \(post)...")
                postBuf.removeValue(forKey: userId)
                markers[userId]?.snippet = post
            }
            }
        }
    }
    
    private func parseFetchMsgRecvReq(_ data: [String: String]) {
        let rawMsgArr = data["Msg"]?.data(using: .utf8)
        let rawArr = try? JSONSerialization.jsonObject(with: rawMsgArr!, options: []) as! [[String : String]]
        for rawItem in rawArr! {
            let userId = rawItem["userId"]!
            let msg = rawItem["post"] ?? ""
            print("user \(userId) posts: \(msg)")
            if let mk = markers[userId] {
                mk.snippet = msg
            } else {
                postBuf[userId] = msg
                print("user \(userId) does not appear in this map, cache it :\(msg)")
            }
        }
    }
    
    private func pollingQueue() {
        let getMsgReq = AWSSQSReceiveMessageRequest()!
        getMsgReq.maxNumberOfMessages = 10
        getMsgReq.waitTimeSeconds = 5
        getMsgReq.queueUrl = myQueueUrl
        print("polling...")
        mySQS.receiveMessage(getMsgReq).continueWith{ (task) -> AnyObject! in
            if let error = task.error{
                print(error)
            }
            if let data = task.result?.messages {
                print("get some message")
                for dd in data {
                    let msgRecp = dd.receiptHandle!
                    let msgBody = dd.body!
                    print(msgBody)
                    self.parseRecvReq(recvReq: msgBody)
                    self.deleteMsgFromQueue(receiptHandle: msgRecp)
                }
            }
            return nil
        }
    }
    
    private func deleteMsgFromQueue(receiptHandle rh: String) {
        let delReq = AWSSQSDeleteMessageRequest()!
        delReq.queueUrl = myQueueUrl
        delReq.receiptHandle = rh
        mySQS.deleteMessage(delReq)
    }
}
