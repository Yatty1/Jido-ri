//
//  TakePhoto.swift
//  faceFeature
//
//  Created by 山田真也 on 2016/09/09.
//  Copyright © 2016年 山田真也. All rights reserved.
//

import AVFoundation
import UIKit

class TakePhoto: UIViewController{

    var session: AVCaptureSession!
    var myDevice: AVCaptureDevice!
    
    var myImageOutput: AVCaptureStillImageOutput!
    
    var myImageData: NSData!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //create session
        session = AVCaptureSession()
        //get device list
        let devices = AVCaptureDevice.devices()
        //front カメラをmyDeviceに格納
        for device in devices{
            if (device.position == AVCaptureDevicePosition.Front){
                myDevice = device as! AVCaptureDevice
            }
        }
        //get VideoInput from Front Camera
        let videoInput = try! AVCaptureDeviceInput.init(device: myDevice)
        //add to session
        session.addInput(videoInput)
        //create output destination
        myImageOutput = AVCaptureStillImageOutput()
        // add to session
        session.addOutput(myImageOutput)
        //create layer to display the image
        let myVideoLayer = AVCaptureVideoPreviewLayer.init(session: session)
        myVideoLayer.frame = self.view.bounds
        myVideoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        //add to view
        self.view.layer.addSublayer(myVideoLayer)
        // start session
        session.startRunning()
        
        // make UIButton
        let takeBtn = UIButton(frame: CGRectMake(0,0,70,70))
        takeBtn.backgroundColor = UIColor.cyanColor()
        takeBtn.layer.masksToBounds = true
        takeBtn.layer.cornerRadius = 35.0
        takeBtn.setTitle("Take", forState: .Normal)
        takeBtn.layer.position = CGPoint(x: self.view.bounds.width/2, y: self.view.bounds.height-50)
        takeBtn.addTarget(self, action: #selector(onclick), forControlEvents: .TouchUpInside)
        
        self.view.addSubview(takeBtn)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    //event
    func onclick(sender: UIButton){
        //connect video output
        let myVideoConnection = myImageOutput.connectionWithMediaType(AVMediaTypeVideo)
        //get image from connection
        self.myImageOutput.captureStillImageAsynchronouslyFromConnection(myVideoConnection, completionHandler: {(imageDataBuffer, error) -> Void in
            if let e = error {
                print(e.localizedDescription)
                return
            }
            //convert databuffer to jpeg
            self.myImageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataBuffer)
            
        })
        session.stopRunning()
        confirmAlert("この角度で保存しますか？")
        
    }
    
    
    //角度を登録する際の確認アラート
    func confirmAlert(title: String){
        
        let alert = UIAlertController(title: "\(title)",
                                      message: "",
                                      preferredStyle: .Alert)
        
        //alertでok押した時の処理
        func save(action: UIAlertAction){
            // create UIImage from jpeg
            let myImage = UIImage(data: self.myImageData)!
            // add to album
            UIImageWriteToSavedPhotosAlbum(myImage, self, nil, nil)
            
            self.dismissViewControllerAnimated(true, completion: nil)
            
        }
        
        //cencelのときはもう一度カメラが動きだす
        func oneMore(action: UIAlertAction){
            session.startRunning()
        }
        

        let okAction = UIAlertAction(title: "OK",
                                   style: .Default,
                                   handler: save)
        let cancelAction = UIAlertAction(title: "もう一度",
                                         style: .Cancel,
                                         handler: oneMore)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
            }
    
   }
