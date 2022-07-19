//
//  ViewController.swift
//  MQTT-Multiple-Topics
//
//  Created by Shivaditya Kumar on 17/07/22.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var topicOneSwitch: UISwitch!
    @IBOutlet weak var topicTwoSwitch: UISwitch!
    @IBOutlet weak var topicThreeSwitch: UISwitch!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.topicOneSwitch.isOn = false
        self.topicTwoSwitch.isOn = false
        self.topicThreeSwitch.isOn = false
        self.topicOneSwitch.addTarget(self, action: #selector(topicOne), for: .touchUpInside)
        self.topicTwoSwitch.addTarget(self, action: #selector(topicTwo), for: .touchUpInside)
        self.topicThreeSwitch.addTarget(self, action: #selector(topicThree), for: .touchUpInside)
        let handler : ((_ response : JSONResponse?)->()) = { response in
            guard let response = response else {return}
            debugPrint("Topic One")
            debugPrint(response as Any)
        }
        let handler1 : ((_ response : JSONResponse?)->()) = { response in
            guard let response = response else {return}
            debugPrint("Topic Two")
            debugPrint(response as Any)
        }
        MQTTManager.shared.getMessageFromTopic(forTopic: "testTopic", completionHandler: handler)
        
        MQTTManager.shared.getMessageFromTopic(forTopic: "testTopic1", completionHandler: handler1)
    }
    @IBAction func didTapConnect(_ sender: Any) {
        MQTTManager.shared.establishConnection()
    }
    @objc func topicOne() {
        let isOn = self.topicOneSwitch.isOn
        isOn ? debugPrint("ON"): debugPrint("OFF")
        isOn ? MQTTManager.shared.subscribe(topicName: "testTopic") { _ in} : MQTTManager.shared.unSubscribe(topicName: "testTopic") { _ in}
    }
    @objc func topicTwo() {
        let isOn = self.topicTwoSwitch.isOn
        isOn ? debugPrint("ON"): debugPrint("OFF")
        isOn ? MQTTManager.shared.subscribe(topicName: "testTopic1") { _ in} : MQTTManager.shared.unSubscribe(topicName: "testTopic1") { _ in}
    }
    @objc func topicThree() {
        // For Third Topic if have.
    }
}

