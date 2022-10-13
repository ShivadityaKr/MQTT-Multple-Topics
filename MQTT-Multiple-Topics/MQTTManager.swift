//
//  MQTTManager.swift
//  NextRewards
//
//  Created by Shivaditya Kumar on 14/07/22.
//

import Foundation
import MQTTNIO //https://github.com/sroebert/mqtt-nio.git

class MQTTManager: NSObject {
    static var shared = MQTTManager(credential: AppMQTTCredential())
    var client: MQTTClient
    
    var topicList = Set<String>()
    private init(credential: AppMQTTCredential) {
        self.client = MQTTClient(
            configuration: .init(
                target: .host(credential.host, port: credential.port),
                clientId: credential.clientID,
                credentials: .init(username: credential.username, password: credential.password)
            ),eventLoopGroupProvider: .createNew
        )
        super.init()
    }
    func establishConnection() {
        self.client.connect().whenComplete {[weak self] result in
            guard let self = self else {return}
            switch result {
            case .success:
                debugPrint("Connected")
                // When Connection lost then it automatically subscribes topics.
                if self.topicList.count != 0 {
                    debugPrint("Subscribing Topics")
                    let list = Array(self.topicList)
                    self.subscribe(topics: list) { _ in }
                }
            case .failure(let error):
                debugPrint("Didn't Connect : \(error)")
            }
        }
    }
    func subscribe(topicName: String, completion: @escaping (Error?) -> Void) {
        self.client.subscribe(to: [topicName], qos: .atLeastOnce, options: .init(), identifier: nil, userProperties: []).whenComplete { [weak self] result in
            guard let self = self else {return}
            switch result {
            case .success:
                self.topicList.insert(topicName)
//                self.disconnectInternal()
                completion(nil)
                debugPrint("Subscribed \(topicName)")
            case .failure(let error):
                completion(error)
            }
        }
        
    }
    func subscribe(topics: [String], completion: @escaping (Error?) -> Void) {
        self.client.subscribe(to: topics, qos: .atLeastOnce, options: .init(), identifier: nil, userProperties: []).whenComplete { [weak self] result in
            guard let self = self else {return}
            switch result {
            case .success:
                topics.forEach { topic in
                    self.topicList.insert(topic)
                }
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    func unSubscribe(topicName: String, completion: @escaping (Error?) -> Void) {
        self.client.unsubscribe(from: topicName).whenComplete { result in
            switch result {
            case .success:
                completion(nil)
                debugPrint("UnSubscribed \(topicName)")
                self.topicList.remove(topicName)
            case .failure(let error):
                completion(error)
            }
        }
    }
    func getMessageFromTopic<RESPONSE : Codable>(forTopic: String, completionHandler : @escaping((_ response : RESPONSE?) -> Void)) {
        self.client.whenMessage(forTopic: forTopic) { message in
            let buffer = message.payload
            let string = buffer.string
            guard let data = string?.data(using: .utf8) else {
                completionHandler(nil)
                return
            }
            if let jsonData = try? JSONDecoder().decode(RESPONSE.self, from: data) {
                completionHandler(jsonData)
                debugPrint(jsonData)
            } else {
                completionHandler(nil)
            }
        }
    }
    private func disconnectInternal() {
        self.client.disconnect().whenComplete { [weak self] result in
            guard let self = self else {return}
            switch result {
            case .success:
                debugPrint("Disconnect internally...")
                self.establishConnection()
            case .failure:
                break
            }
        }
    }
    func disconnectMQTT() {
        self.client.disconnect().whenComplete {result in
            switch result {
            case .success:
                debugPrint("Success")
            case .failure:
                debugPrint("failure")
            }
        }
    }
    deinit {
        if self.client.isConnected {
            self.disconnectMQTT()
        }
    }
    
    struct AppMQTTCredential {
        let username = "username"
        let password = "password"
        let port = 1883
        let host = "host"
        let clientID = "ClientID-" + String(ProcessInfo().processIdentifier)
    }
}
extension MQTTManager {
    func whenConnecting(completion: @escaping ((Bool, Error?)-> Void)) {
        self.client.whenConnecting { error in
            if let error {
                completion(false,error)
            } else {
                completion(true,nil)
            }
        }
    }
}
extension MQTTManager {
    func whenConnected(completion: @escaping ((Bool, Error?)-> Void)) {
        self.client.whenConnected { error in
            if let error {
                completion(false,error)
            } else {
                completion(true,nil)
            }
        }
    }
}
extension MQTTManager {
    func whenDisconnected(completion: @escaping ((Bool, Error?)-> Void)) {
        self.client.whenDisconnected { error in
            if let error {
                completion(false,error)
            } else {
                completion(true,nil)
            }
        }
    }
}
extension MQTTManager {
    func whenConnectionFailure(completion: @escaping ((Bool, Error?)-> Void)) {
        self.client.whenConnectionFailure { error in
            if let error {
                completion(false,error)
            } else {
                completion(true,nil)
            }
        }
    }
}