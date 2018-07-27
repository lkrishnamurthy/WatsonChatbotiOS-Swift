//
//   ViewController.swift
//   WatsonChatbotiOSStarter
//

import UIKit
import SwiftSpinner
import JSQMessagesViewController
import IBMMobileFirstPlatformFoundation
import BMSCore




class ViewController: JSQMessagesViewController {

    // Configure chat settings for JSQMessages
    let incomingChatBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    let outgoingChatBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    fileprivate let kCollectionViewCellHeight: CGFloat = 12.5

    // Configure Watson Conversation items
    var conversationMessages = [JSQMessage]()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.setupTextBubbles()
        // Remove attachment icon from toolbar
        self.inputToolbar.contentView.leftBarButtonItem = nil

        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }

    func reloadMessagesView() {
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      SwiftSpinner.show("Connecting to Watson", animated: true)
      invokeMFPAdapter(text: "");
   }

    func didBecomeActive(_ notification: Notification) {
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // Function to show an alert with an alertTitle String and alertMessage String
    func showAlert(_ alertTitle: String, alertMessage: String){
        // If an alert is not currently being displayed
        if(self.presentedViewController == nil){
            // Set alert properties
            let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
            // Add an action to the alert
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
            // Show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }

    // Setup text bubbles for conversation
    func setupTextBubbles() {
        // Create sender Id and display name for user
        self.senderId = "TestUser"
        self.senderDisplayName = "TestUser"
        // Set avatars for user and Watson
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 28, height:32 )
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 37, height:37 )
        automaticallyScrollsToMostRecentMessage = true

    }
    // Set how many items are in the collection view
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.conversationMessages.count
    }

    // Set message data for each item in the collection view
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return self.conversationMessages[indexPath.row]

    }

    // Set whih bubble image is used for each message
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        return conversationMessages[indexPath.item].senderId == self.senderId ? outgoingChatBubble : incomingChatBubble

    }

    // Set which avatar image is used for each chat bubble
    override func collectionView(_ collectionView: JSQMessagesCollectionView, avatarImageDataForItemAt indexPath: IndexPath) -> JSQMessageAvatarImageDataSource? {
        let message = conversationMessages[(indexPath as NSIndexPath).item]
        var avatar: JSQMessagesAvatarImage
        if (message.senderId == self.senderId){
            avatar  = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named:"avatar_small"), diameter: 37)
        }
        else{
            avatar  = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named:"watson_avatar"), diameter: 32)
        }
        return avatar
    }

    // Create and display timestamp for every third message in the collection view
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
        if ((indexPath as NSIndexPath).item % 3 == 0) {
            let message = conversationMessages[(indexPath as NSIndexPath).item]
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }
        return nil
    }

    // Set the height for the label that holds the timestamp
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as NSIndexPath).item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return kCollectionViewCellHeight
    }

    // Create the cell for each item in collection view
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
            as! JSQMessagesCollectionViewCell
        let message = self.conversationMessages[(indexPath as NSIndexPath).item]
        // Set the UI color of each cell based on who the sender is
        if message.senderId == senderId {
            cell.textView!.textColor = UIColor.black
        } else {
            cell.textView!.textColor = UIColor.white
        }
        return cell
    }

    // Handle actions when user presses send button
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        // Create message based on user text
        let message = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text)
        // Add message to conversation messages array of JSQMessages
        self.conversationMessages.append(message!)
        DispatchQueue.main.async {
            self.finishSendingMessage()
        }
        invokeMFPAdapter(text: text);
    }

    func convertToJSONObj(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }

    func invokeMFPAdapter (text: String) {
        /*
         * MFP Adapter invocation
         * Eg Adapter EndPoint: http://localhost:9080/mfp/api/adapters/WatsonConversation/v1/workspaces/YOUR_WORKSPACE_ID/message?version=2017-05-26
         *
         */

        let url = URL(string: "/adapters/WatsonConversation/v1/workspaces/73e93b46-6594-43d1-8597-ef586885fc90/message")
        let request = WLResourceRequest(url: url, method: WLHttpMethodPost)
        
        // About conversation service api refer : https://watson-api-explorer.mybluemix.net/apis/conversation-v1#/
        var jsonInput = "";
        if (text.isEmpty) { //defaults to start message
            //jsonInput = "{\"input\": {\"text\":\"" + text + "\"}, \"context\": {\"conversation_id\": \"1b7b67c0-90ed-45dc-8508-9488bc483d5b\", \"system\": {\"dialog_stack\": [{\"dialog_node\": \"root\"}],\"dialog_turn_counter\": 0, \"dialog_request_counter\":0}}, \"alternateIntents\":true}"
            jsonInput = "{\"input\": {\"text\":\"" + "Hello" + "\"}, \"alternateIntents\":true}"
        } else {
            //jsonInput = "{\"input\": {\"text\":\"" + text + "\"}, \"context\": {\"conversation_id\": \"1b7b67c0-90ed-45dc-8508-9488bc483d5b\", \"system\": {\"dialog_stack\": [{\"dialog_node\": \"root\"}],\"dialog_turn_counter\": 1, \"dialog_request_counter\":1}}, \"alternateIntents\":true}"
            jsonInput = "{\"input\": {\"text\":\"" + text + "\"}, \"alternateIntents\":true}"
        }

        request?.setQueryParameterValue("2018-02-16", forName: "version")
        request?.send(withJSON: convertToJSONObj(text: jsonInput), completionHandler: { (response, error) in
            if(error == nil){
                //print ("# MPF ping/adapter call success # ", response?.responseText)
                let data = response?.responseData
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:Any]
                    if let outputTextArr = json["output"] as? [String: NSArray] {
                        if let msg = outputTextArr["text"]?[0] as? String {
                            // Create message based on Watson response
                            let message = JSQMessage(senderId: "Watson", displayName: "Watson", text: msg)
                            // Add message to conversation message array
                            self.conversationMessages.append(message!)
                            DispatchQueue.main.async {
                                self.finishSendingMessage()
                                SwiftSpinner.hide()
                            }
                        }
                    }
                } catch let error as NSError {
                    print(error)
                }
            }
            else{
                self.finishSendingMessage()
                SwiftSpinner.hide()
                let errDesc = error?.localizedDescription
                self.showAlert("Error ", alertMessage: errDesc!)
            }
        });
    }
}
