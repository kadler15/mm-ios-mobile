//
//  BackgroundInfoOptionalViewController.swift
//  MiracleMessages
//
//  This is the screen where optional questions are shown.
//
//  Created by Shobhit on 2017-11-06.
//  Copyright © 2017 Win Inc. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import Firebase

class BackgroundInfoOptionalViewController: UIViewController, NVActivityIndicatorViewable, UITextViewDelegate {
    let currentCase: Case = Case.current
    var ref: DatabaseReference!
    // Container to set text why they lost touch with loved ones.
    @IBOutlet weak var mLooseTouchReasonText: UITextView!

    // Container to set reason for homelessness.
    @IBOutlet weak var mHomelessReason: UITextView!
    
    // Handles click of next button on screen.
    @IBAction func onClickNext(_ sender: Any) {
        updateBackgroundInfo(isTopNext:false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set placeholder text
        ref = Database.database().reference()
        
        mLooseTouchReasonText.delegate = self
        mHomelessReason.delegate = self
        mLooseTouchReasonText.placeholder = "Answer (optional)"
        mHomelessReason.placeholder = "Answer (optional)"
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(btnNextTapped(sender:)))
    }
    
    func btnNextTapped(sender: UIBarButtonItem) {
        self.updateBackgroundInfo(isTopNext:true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        displayInfo()
    }
    
    func displayInfo() -> Void {
        if let caseResearch = currentCase.research {
            mLooseTouchReasonText.text = caseResearch.quest1
            mHomelessReason.text = caseResearch.quest2
        }
    }
        
    func updateBackgroundInfo(isTopNext: Bool) -> Void {
        self.ShowActivityIndicator()
        currentCase.research = (mLooseTouchReasonText.text, mHomelessReason.text)
        
        var txtmLooseTouchReason : String = ""
        var txtmHomelessReason : String = ""
        
        if let mLooseTouchReason = mLooseTouchReasonText.text{
            txtmLooseTouchReason = mLooseTouchReason
        }
        
        if let mHomelessReason = mHomelessReason.text{
            txtmHomelessReason = mHomelessReason
        }
        
        guard let key = currentCase.key else {return}
        
        let caseReference: DatabaseReference
        caseReference = self.ref.child("/cases/\(key)")
        let publicPayload: [String: Any] = [
            "research":["quest1": txtmLooseTouchReason , "quest2":txtmHomelessReason]
        ]
        print("Public Payload\(publicPayload)")
        
        // Write case data
        caseReference.updateChildValues(publicPayload) { error, _ in
            // If unsuccessful, print and return
            self.RemoveActivityIndicator()
            guard error == nil else {
                self.showAlertView()
                print(error!.localizedDescription)
                Logger.log(error!.localizedDescription)
                Logger.log("\(publicPayload)")
                return
            }
            
            if(isTopNext == true){
                self.performSegue(withIdentifier: "backgroundInfoOptional", sender: nil)
            }
            
        }
        
    }
     
    func showAlertView(){
        // create the alert
        let alert = UIAlertController(title: "Miracle Messages", message: "Something went wrong. please try again later.", preferredStyle: UIAlertControllerStyle.alert)
        
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    //Show activity indicator while saving data
    func ShowActivityIndicator(){
        
        let size = CGSize(width: 50, height:50)
        startAnimating(size, message: nil, type: NVActivityIndicatorType(rawValue: 6)!)
    }
    
    //Remove activity indicator
    func RemoveActivityIndicator(){
        stopAnimating()
    }
}
