//
//  JsonReqHelper.swift
//  MySampleApp
//
//  Created by Jingxuan Zhang on 4/29/17.
//  Improved by Yongyi Yang on 1/5/17
//

import Foundation

enum ReqType {
    case updateLoc
    case postMsg
    case fetchMsg
}

class JsonReqHelper {
    
    func getSendReq(withType t: ReqType) -> String {
        return "asd"
    }
    
    func parseRecvReq(recvReq jsonText: String) {
        let data = jsonText.data(using: .utf8)
        let parsedDataArray = try? JSONSerialization.jsonObject(with: data!, options: []) as! Array<Any>
        for dataItem in parsedDataArray! {
            let parsedItem = dataItem as! [String: Any]
            switch (parsedItem["Method"] as! String) {
            case "updateLoc":
                parseUpdateLocRecvReq(parsedItem)
            default:
                print("Error! No corresponding method found")
            }
        }
    }
    
    private func parseUpdateLocRecvReq(_ data: [String: Any]) -> [[String: Any]] {
        var ret = [[String: Any]]()
        let rawLocArr = (data["Loc"] as! [[String: Any]])
        for rawLocItem in rawLocArr {
            let locItem = rawLocItem["longitude"]
        }
        return ret
    }

}

class ReqCollector {
    var arr = [[String: Any]]()
    
    func append(request req: [String: Any]) {
        arr.append(req)
    }
    
    func getReqText() -> String {
        let jsonData = try? JSONSerialization.data(withJSONObject: arr, options: [])
        return String(data: jsonData!, encoding: .utf8)!
    }
}

class BaseReq {
    var userId : String = ""
    var userQueue : String = ""
    
    func setUserId(_ uid: String) {
        self.userId = uid
    }
    
    func setUserQueue(_ uq: String) {
        self.userQueue = uq
    }
}

class UpdateLocSendReq : BaseReq {
    private var longitude : Double = 0.0
    private var latitude : Double = 0.0
    
    init(Username uid: String, UserQueue uq: String) {
        super.init()
        self.setUserId(uid)
        self.setUserQueue(uq)
    }
    
    func setLongitude(_ longti: Double) {
        self.longitude = longti
    }
    
    func setLatitude(_ lati: Double) {
        self.latitude = lati
    }
    
    func getReq() -> [String: Any] {
        return ["Method": "updateLoc",
                    "Loc" :
                        ["Latitude": latitude,
                         "Longitude": longitude],
                    "userQueue" : userQueue,
                    "userId": userId]
    }
}

class PostMsgSendReq : BaseReq {
    private var msg : String!
    private var expiration : Int = 600
    
    init(Username uid: String, UserQueue uq: String) {
        super.init()
        self.setUserId(uid)
        self.setUserQueue(uq)
    }
    
    func setMessage(Post msg: String) {
        self.msg = msg
    }
    
    func setExpireTime(empireTimeInSec t: Int) {
        self.expiration = t
    }
    
    func getReq() -> [String: Any] {
        return ["Method": "postMsg",
                "Msg": self.msg,
                "Expire": self.expiration,
                "userId": self.userId,
                "userQueue": self.userQueue]
    }
}

class FetchMsgSendReq : BaseReq {
    
    init(Username uid: String, UserQueue uq: String) {
        super.init()
        self.setUserId(uid)
        self.setUserQueue(uq)
    }
    
    func getReq() -> [String: Any] {
        return ["Method": "fetchMsg",
                "userId": self.userId,
                "userQueue": self.userQueue]
    }
}
