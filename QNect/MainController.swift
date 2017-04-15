//
//  MainController.swift
//  QNect
//
//  Created by Panucci, Julian R on 3/28/17.
//  Copyright © 2017 Julian Panucci. All rights reserved.
//

import UIKit
import Pageboy
import AVFoundation
import TransitionTreasury
import TransitionAnimation
import PTPopupWebView

class MainController: PageboyViewController, NavgationTransitionable, ModalTransitionDelegate  {
    
    /// Transiton delegate
    var tr_presentTransition: TRViewControllerTransitionDelegate?
    var tr_pushTransition: TRNavgationTransitionDelegate?
    
    //MARK: Constants
    let kDismissString = "Dismiss"
    let kPinchVelocity = 8.0
    

    //MARK: Properties
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    var placeHolderViewController: UIViewController!
    var profileNavController: UINavigationController!
    var connectionsNavController: UINavigationController!
    
    var profileViewController: ProfileViewContoller!
    var connectionsViewController: ConnectionsViewController!
    
    var colorView: GradientView!
    var contactImage:UIImage?
    let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var contact: User!
    var qrCodeFrameView = UIImageView()
    var rightBarButton: UIButton!
    
    
    var scannedContact = 0
    var toFromIndex: (Int, Int) = (0, 0)
    var showURLAlert = 0
    var scannerCanScan = true
    var message: String?
    
    
    
    //MARK: Actions
    
    @IBAction func gesture(_ sender: AnyObject) {
        handlePinch(sender)
    }
    
    //MARK: Lifecycle
    
     override func viewDidLoad() {
        super.viewDidLoad()

        colorView = GradientView(frame: view.frame)
        view.insertSubview(colorView, at: 0)
        colorView.colors = [ #colorLiteral(red: 0.123675175, green: 0.9002516866, blue: 0.7746840715, alpha: 1).cgColor, #colorLiteral(red: 0.02568417229, green: 0.4915728569, blue: 0.614921093, alpha: 1).cgColor,]
        colorView.alpha = 0.0
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        profileNavController = storyboard.instantiateViewController(withIdentifier: "ProfileViewControllerNav") as! UINavigationController
       connectionsNavController = storyboard.instantiateViewController(withIdentifier: "ConnectionsViewControllerNav") as! UINavigationController
        placeHolderViewController = UIViewController()
        placeHolderViewController.view.alpha = 0.0
        
        profileViewController = profileNavController.viewControllers.first as! ProfileViewContoller
        connectionsViewController = connectionsNavController.viewControllers.first as! ConnectionsViewController
        
        QnClient.sharedInstance.currentUser { (currentUser) in
            self.profileViewController.configureViewController(displayCurrentUserProfile: true, user: currentUser)
        }
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(MainController.interactiveTransition(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)
        
        createCaptureSession()
        startCaptureSession()
        createBarButtonItems()
        
        self.dataSource = self
        self.delegate = self
    }
    
    //MARK: UI Setup
    
    func createBarButtonItems() {
        //todo: add/find functionality for bar button item
        rightBarButton = UIButton()
        rightBarButton.setImage(#imageLiteral(resourceName: "qnect_q"), for: .normal)
        rightBarButton.frame = CGRect(x: 0, y: 0, width: 45, height: 45)
        
        let rightItem: UIBarButtonItem = UIBarButtonItem()
        rightItem.customView = rightBarButton
        
        self.navigationItem.rightBarButtonItem = rightItem
    }
    
    //MARK: Capture Session
    
    func createCaptureSession()
    {
        var error:NSError?
        let input:AnyObject!
        do {
            input = try AVCaptureDeviceInput(device: captureDevice)
        } catch let error1 as NSError {
            error = error1
            input = nil
        }
        
        if error != nil{
            print("\(error?.localizedDescription)")
        } else {
            captureSession = AVCaptureSession()
            captureSession?.addInput(input as! AVCaptureInput)
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.insertSublayer(videoPreviewLayer, at: 0)
        }
    }
    
    func startCaptureSession()
    {
        captureSession?.startRunning()
    }
    
    func stopCaptureSession()
    {
        captureSession?.stopRunning()
    }
    
    //todo: Change Transisition
    func interactiveTransition(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            guard sender.velocity(in: view).y > 0 else {
                break
            }
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CodeController")  as! QnectCodeViewController
            vc.modalDelegate = self
            
            tr_presentViewController(vc, method: TRPresentTransitionMethod.scanbot(present: sender, dismiss: vc.dismissGestureRecognizer), completion: {
            })
        default: break
        }
    }
    
    
    func modalViewControllerDismiss(interactive: Bool, callbackData data: Any?) {
        tr_dismissViewController(interactive, completion: nil)
    }
    
    //MARK: Functionality
    
    func handleScannedContact(_ metadataObj:AVMetadataMachineReadableCodeObject, barCodeObject:AVMetadataMachineReadableCodeObject)
    {
        self.stopCaptureSession()
        segueToContactViewController()
    }
    
    func centerForBarcodeObject(_ barCodeObject:AVMetadataMachineReadableCodeObject) -> CGPoint
    {
        let centerX = barCodeObject.bounds.origin.x + (barCodeObject.bounds.size.width / 2.0)
        let centerY = barCodeObject.bounds.origin.y + (barCodeObject.bounds.size.height / 2.0)
        let center = CGPoint(x: centerX, y: centerY)
        return center
    }
    
    /// Pinch to zoom
    ///
    /// - Parameter sender: pinch gesture
    func handlePinch(_ sender: AnyObject)
    {
        let pinchVelocityDividerFactor = kPinchVelocity;
        
        
        if (sender.state == UIGestureRecognizerState.changed) {
            let pinch = sender as! UIPinchGestureRecognizer
            do {
                try captureDevice?.lockForConfiguration()
                
                let desiredZoomFactor = Double((captureDevice?.videoZoomFactor)!) + atan2(Double(pinch.velocity), pinchVelocityDividerFactor)
                
                captureDevice?.videoZoomFactor = max(1.0,min(CGFloat(desiredZoomFactor), (captureDevice?.activeFormat.videoMaxZoomFactor)!))
                
                captureDevice?.unlockForConfiguration()
            }catch let error as NSError {
                print(error)
            }
        }
    }
    
    //MARK: Segue
    
    func segueToContactViewController() {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    

}

//MARK: Scanner Delegate

extension MainController: AVCaptureMetadataOutputObjectsDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        
        guard scannerCanScan else {
            //If scannerCanScan is set to true we must be on a different page where we will not allow scanning
            return
        }
        
        if metadataObjects == nil || metadataObjects.count == 0 {
            showURLAlert = 0
            return
        } else {
            
            let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj as AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
            
            if metadataObj.type == AVMetadataObjectTypeQRCode{
                if let contact = QnDecoder.decodeQRCode(metadataObj.stringValue) {
                    
                    self.contact = contact
                    
                    handleScannedContact(metadataObj, barCodeObject: barCodeObject)
                    
                }else if metadataObj.stringValue.contains(".com") {
                    
                    //Todo: Need to test different QRCodes and handle different strings
                    var url = ""
                    if !metadataObj.stringValue.contains("http"){
                        url = "http://\(metadataObj.stringValue)"
                    }else {url = metadataObj.stringValue}
                    
                    
                    let popupvc = PTPopupWebViewController()
                    popupvc.popupView.URL(string: url)
                    let closeButton = PTPopupWebViewButton(type: .custom).title("Close").foregroundColor(UIColor.qnBlue)
                    closeButton.handler({
                        self.startCaptureSession()
                        popupvc.close()
                    })
                    
                    let safariButton = PTPopupWebViewButton(type: .custom).backgroundColor(UIColor.qnBlue).foregroundColor(UIColor.white)
                    safariButton.title("Open in Safari")
                    safariButton.handler({
                        UIApplication.shared.openURL(URL(string: url)!)
                    })
                    
                    popupvc.popupView.addButton(safariButton)
                    popupvc.popupView.addButton(closeButton)
                    popupvc.show()
                    self.stopCaptureSession()
                }
                else {
                    let alert = UIAlertController(title: nil, message: metadataObj.stringValue, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: kDismissString, style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}

//MARK: Pageboy Delegate

extension MainController: PageboyViewControllerDelegate {
    
    func pageboyViewController(_ pageboyViewController: PageboyViewController,
                               willScrollToPageAtIndex index: Int,
                               direction: PageboyViewController.NavigationDirection,
                               animated: Bool) {
        //If we are scrolling then disable scanning
        scannerCanScan = false
        self.navigationController?.navigationBar.barTintColor = .clear
        
        toFromIndex = calculateToFromIndexTuple(direction: direction, index: index)
    }
    
    func pageboyViewController(_ pageboyViewController: PageboyViewController,
                               didScrollToPosition position: CGPoint,
                               direction: PageboyViewController.NavigationDirection,
                               animated: Bool) {
        updateColorViewAlpha(position: position)
    }
    
    func pageboyViewController(_ pageboyViewController: PageboyViewController,
                               didScrollToPageAtIndex index: Int,
                               direction: PageboyViewController.NavigationDirection,
                               animated: Bool) {
        
        //If not on the scanner page then we do not allow scanning
        scannerCanScan = index != 1 ? false : true
    }
    
    func calculateToFromIndexTuple(direction: PageboyViewController.NavigationDirection, index: Int) -> (Int, Int)
    {
        let toIndex = index
        var fromIndex = 0

        if direction == .reverse && index == 0 {
            fromIndex = 1
        }
        
        if direction == .forward && index == 1 {
            fromIndex = 0
        }
        
        if direction == .reverse && index == 1 {
            fromIndex = 2
        }
        
        if direction == .forward && index == 2 {
            fromIndex = 1
        }
        
        return(toIndex, fromIndex)
    }
    
    func updateColorViewAlpha(position: CGPoint) {
        switch toFromIndex {
        case (1, 0), (0, 1):
            colorView.colors = [ #colorLiteral(red: 0.123675175, green: 0.9002516866, blue: 0.7746840715, alpha: 1).cgColor, #colorLiteral(red: 0.02568417229, green: 0.4915728569, blue: 0.614921093, alpha: 1).cgColor,]
            colorView.alpha = 1 - position.x
            rightBarButton.alpha = position.x
        case (2, 1), (1, 2):
            colorView.colors = [#colorLiteral(red: 0.05098039216, green: 0.9607843137, blue: 0.8, alpha: 1).cgColor, #colorLiteral(red: 0.0431372549, green: 0.5764705882, blue: 0.1882352941, alpha: 1).cgColor]
            colorView.alpha = position.x - 1
        default:
            break
        }
    }

}

//MARK: Pageboy Datasource

extension MainController: PageboyViewControllerDataSource {
    func viewControllers(forPageboyViewController pageboyViewController: PageboyViewController) -> [UIViewController]? {
        // return array of view controllers
        return [profileNavController, placeHolderViewController, connectionsNavController]
    }
    
    func defaultPageIndex(forPageboyViewController pageboyViewController: PageboyViewController) -> PageboyViewController.PageIndex? {
        // set ScannerViewController as first controller you see at index 1. Which is in the middle
        return PageIndex.atIndex(index: 1)
    }
    
}


//MARK: Gesture Delegate

extension MainController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let ges = gestureRecognizer as? UIPanGestureRecognizer {
            return ges.translation(in: ges.view).y != 0
        }
        return false
    }
}


