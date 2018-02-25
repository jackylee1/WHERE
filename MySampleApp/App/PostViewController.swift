//
//  PostViewController.swift
//  MySampleApp
//
//  Created by Jingxuan Zhang on 4/24/17.
//  Improved by Yongyi Yang on 1/5/17
//

import UIKit
import AWSMobileHubHelper
import AWSSQS

class PostViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {
    
    // MARK: Properties
    @IBOutlet weak var postTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var username : String! = nil
    var queueUrl : String! = nil
    var mySQS : AWSSQS! = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        postTextField.delegate = self
        
        print(username)
        print(queueUrl)
        
        updateSaveButtonState()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing
        saveButton.isEnabled = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func sendPost(_ sender: UIBarButtonItem) {
        
        let postText = postTextField.text ?? ""
        print("sending the post \(postText)")
        let req = ReqCollector()
        let postReq = PostMsgSendReq(Username: username, UserQueue: queueUrl)
        postReq.setMessage(Post: postText)
        req.append(request: postReq.getReq())
        
        let sendReq = AWSSQSSendMessageRequest()!
        sendReq.messageBody = req.getReqText()
        sendReq.queueUrl = "https://sqs.us-east-1.amazonaws.com/ /send_que"
        mySQS.sendMessage(sendReq)
        print("message sent")
        
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Private Methods
    
    private func updateSaveButtonState() {
        // Disable the Save button if the text field is empty
        let text = postTextField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
}
