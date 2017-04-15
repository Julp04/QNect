//
//  AccountsViewController.swift
//  
//
//  Created by Panucci, Julian R on 3/17/17.
//
//

import UIKit
import LTMorphingLabel
import Social
import Accounts
import RKDropdownAlert
import FCAlertView


class AccountsViewController: UIViewController {

    //MARK: Properties
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK: Outlets
    @IBOutlet weak var twitterTitleLabel: LTMorphingLabel! {
        didSet {
            twitterTitleLabel.morphingEffect = .evaporate
        }
    }
    @IBOutlet weak var twitterButton: SwitchButton! {
        didSet {
            twitterButton.onTintColor = .twitter
        }
    }
    @IBOutlet weak var twitterDescriptionLabel: LTMorphingLabel! {
        didSet {
            twitterDescriptionLabel.morphingEffect = .scale
        }
    }
    @IBOutlet weak var twitterImageView: UIImageView! {
        didSet {
            let twitter = #imageLiteral(resourceName: "twitter_on").withRenderingMode(.alwaysTemplate)
            twitterImageView.image = twitter
            twitterImageView.tintColor = UIColor.twitter
        }
    }
    
    @IBOutlet weak var contactButton: SwitchButton! {
        didSet {
            contactButton.onTintColor = .qnGreen
        }
    }
    @IBOutlet weak var contactTitleLabel: LTMorphingLabel! {
        didSet {
            contactTitleLabel.morphingEffect = .evaporate
        }
    }
    @IBOutlet weak var contactDescriptionLabel: LTMorphingLabel! {
        didSet {
            contactDescriptionLabel.morphingEffect = .scale
        }
    }
    @IBOutlet weak var contactImageView: UIImageView! {
        didSet {
            let contactImage = #imageLiteral(resourceName: "contact_logo").withRenderingMode(.alwaysTemplate)
            contactImageView.image = contactImage
            contactImageView.tintColor = .qnGreen
        }
    }
    
    
    var twitterWhiteFlake: Snowflake!
    var twitterBlueFlake: Snowflake!
    var contactGreenFlake: Snowflake!
    var contactWhiteFlake: Snowflake!

    //MARK: Actions
    
    @IBAction func continuAction(_ sender: Any) {
        continueToMainVC()
    }
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTwitterButton()
        setupContactButton()
        view.backgroundColor = .qnPurple
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: Functionality
    
    func continueToMainVC() {
        let mainVC = self.storyboard?.instantiateViewController(withIdentifier: "MainControllerNav") as! UINavigationController
        
        self.present(mainVC, animated: true, completion: nil)
    }
    
  
    func setupTwitterButton()
    {
        let twitterParticles = [#imageLiteral(resourceName: "twitter_icon")]
        twitterWhiteFlake = Snowflake(view: twitterButton, particles: twitterParticles, color: .white)
        twitterBlueFlake = Snowflake(view: twitterButton, particles: twitterParticles, color: .twitter)
        twitterButton.layer.addSublayer(twitterBlueFlake)
        twitterButton.layer.addSublayer(twitterWhiteFlake)
        
        twitterBlueFlake.start()
        
        twitterButton.onClick = {
            TwitterClient().linkTwitterIn(viewController: self, completion: { (error) in
                guard error == nil else {
                    RKDropdownAlert.title("Oops!", message: error?.localizedDescription, backgroundColor: .qnRed, textColor: .white)
                    return
                }
                self.turnOnTwitterButton()
            })
        }
    }
    
    func setupContactButton()
    {
        contactButton.onTintColor = .qnGreen
        
        let contactParticles = [#imageLiteral(resourceName: "message_particle"), #imageLiteral(resourceName: "phone_particle")]
        contactWhiteFlake = Snowflake(view: contactButton, particles: contactParticles, color: .white)
        contactGreenFlake = Snowflake(view: contactButton, particles: contactParticles, color: .qnGreen)
        contactButton.layer.addSublayer(contactWhiteFlake)
        contactButton.layer.addSublayer(contactGreenFlake)
        
        contactGreenFlake.start()
        
        switch ContactManager.contactStoreStatus() {
        case .authorized:
            turnOnContactButton()
        default:
            break
        }
        
        contactButton.onClick = {
            ContactManager().requestAccessToContacts { accessGranted in
                if accessGranted {
                    self.turnOnContactButton()
                }else {
                    //Show alert that user can turn on access to contacts in settings
                    DispatchQueue.main.async {
                        let alert = FCAlertView()
                        alert.addButton("Settings") {
                            let url = URL(string: UIApplicationOpenSettingsURLString)
                            UIApplication.shared.openURL(url!)
                        }
                        alert.colorScheme = .qnGreen
                        alert.showAlert(inView: self, withTitle: "Access Denied", withSubtitle: "Go to settings to change access to contacts", withCustomImage: #imageLiteral(resourceName: "contact_logo"), withDoneButtonTitle: "Dismiss", andButtons: nil)
                        
                    }
                }
            }
        }
        
        
        
    }
    
    func turnOnTwitterButton()
    {
        self.twitterButton.turnOn()
        self.twitterButton.isEnabled = false
        self.twitterButton.animationDidStartClosure = {_ in
            
            QnClient.sharedInstance.currentUser {user in
                self.twitterTitleLabel.text = user.twitterScreenName!
            }
            self.twitterImageView.tintColor = .white
            self.twitterTitleLabel.textColor = .white
            self.twitterDescriptionLabel.textColor = .white
            self.twitterDescriptionLabel.text = "You are linked with Twitter"
            
        }
        self.twitterButton.animationDidStopClosure = { _, _ in
            self.twitterWhiteFlake.start()
            self.twitterBlueFlake.stop()
        }
    }
    
    func turnOnContactButton()
    {
        contactButton.turnOn()
        contactButton.isEnabled = false
        
        contactButton.animationDidStartClosure = {_ in 
            self.contactTitleLabel.text = "Contacts linked"
            self.contactTitleLabel.textColor = .white
            self.contactDescriptionLabel.textColor = .white
            self.contactImageView.tintColor = .white
        }
        
        contactButton.animationDidStopClosure = {_,_ in 
            self.contactGreenFlake.stop()
            self.contactWhiteFlake.start()
        }
    }
    
    
    
    
    
    
    //MARK: UI
    
    


}
















