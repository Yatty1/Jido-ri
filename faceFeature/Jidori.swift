//
//  Jidori.swift
//  faceFeature
//
//  Created by 山田真也 on 2016/09/09.
//  Copyright © 2016年 山田真也. All rights reserved.
//

import UIKit
import AVFoundation

class Jidori: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    let captureSession = AVCaptureSession()
    let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    //mydevice
    var myDevice: AVCaptureDevice!
    //get device list
    let devices = AVCaptureDevice.devices()
    
    var videoOutput = AVCaptureVideoDataOutput()
    var imageOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
    var myImageData: NSData!

    
    var hideView = UIView()
    
    var capturedImage: UIImage!
    
    var defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
    var angle: Float!

    //label
    var angleLabel : UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //angle label
        angleLabel = UILabel(frame: CGRectMake(0,0,100,50))
        angleLabel.backgroundColor = UIColor.cyanColor()
        angleLabel.textColor = UIColor.whiteColor()
        angleLabel.textAlignment = NSTextAlignment.Center
        angleLabel.layer.masksToBounds = true
        angleLabel.layer.cornerRadius = 20.0
        angleLabel.layer.position = CGPoint(x:self.view.bounds.width/2, y: self.view.bounds.height-50)
        
        //get front camera
        for device in devices{
            if (device.position == AVCaptureDevicePosition.Front){
                myDevice = device as! AVCaptureDevice
            }
        }
        do {
            let videoInput = try! AVCaptureDeviceInput.init(device: myDevice)
            self.captureSession.addInput(videoInput)
        }catch let error as NSError{
            print(error)
        }
        self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_32BGRA)]
        
        //フレームごとに呼び出すデリゲート登録
        let queue: dispatch_queue_t = dispatch_queue_create("myqueue", DISPATCH_QUEUE_SERIAL);
        self.videoOutput.setSampleBufferDelegate(self, queue: queue)
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        
        self.captureSession.addOutput(self.videoOutput)
        self.captureSession.addOutput(self.imageOutput)
        
        let videoLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.view.layer.addSublayer(videoLayer)
        
        //カメラの向き
        for connection in self.videoOutput.connections{
            if let conn = connection as? AVCaptureConnection{
                if conn.supportsVideoOrientation{
                    conn.videoOrientation = AVCaptureVideoOrientation.Portrait
                }
            }
        }
        
        //
        
        hideView = UIView(frame: self.view.bounds)
        self.view.addSubview(hideView)
        self.view.addSubview(angleLabel)
        self.captureSession.startRunning()
    }
    
    
    
    func imageFromSampleBuffer(sampleBuffer: CMSampleBufferRef) -> UIImage {
        //バッファーをUIImageに変換
        let imageBuffer: CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = (CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue)
        let context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, bitmapInfo)
        let imageRef = CGBitmapContextCreateImage(context)
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0)
        let resultImage: UIImage = UIImage(CGImage: imageRef!)
        return resultImage
    }
    
    
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!)
    {
        //同期処理（非同期処理ではキューが溜まりすぎて画像がついていかない）
        dispatch_sync(dispatch_get_main_queue(), {
            
            //バッファーをUIImageに変換
            let image = self.imageFromSampleBuffer(sampleBuffer)
            
            let ciimage:CIImage! = CIImage(image: image)
            
            //CIDetectorAccuracyHighだと高精度（使った感じは遠距離による判定の精度）だが処理が遅くなる
            let detector : CIDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options:[CIDetectorAccuracy: CIDetectorAccuracyLow] )
            let faces : NSArray = detector.featuresInImage(ciimage)
            
            // 検出された顔データを処理
            for subview:UIView in self.hideView.subviews  {
                subview.removeFromSuperview()
            }
            
            var feature : CIFaceFeature = CIFaceFeature()
            
            for feature in faces {
                
                // 座標変換
                var faceRect : CGRect = feature.bounds
                let widthPer = (self.view.bounds.width/image.size.width)
                let heightPer = (self.view.bounds.height/image.size.height)
                
                // UIKitは左上に原点があるが、CoreImageは左下に原点があるので揃える
                faceRect.origin.y = image.size.height - faceRect.origin.y - faceRect.size.height
                
                //倍率変換
                faceRect.origin.x = faceRect.origin.x * widthPer
                faceRect.origin.y = faceRect.origin.y * heightPer
                faceRect.size.width = faceRect.size.width * widthPer
                faceRect.size.height = faceRect.size.height * heightPer
                
                print(feature.faceAngle)
                //アングル表示
                self.angleLabel.text = String(feature.faceAngle)
                self.angle = self.defaults.floatForKey("angle")
                //指定のアングルで写真を撮る
                if (feature.faceAngle == self.angle || feature.faceAngle == -self.angle){
                   
                    //シャッターを押す
                    //connect video output
                    let myVideoConnection = self.imageOutput.connectionWithMediaType(AVMediaTypeVideo)
                    //get image from connection
                    self.imageOutput.captureStillImageAsynchronouslyFromConnection(myVideoConnection, completionHandler: {(imageDataBuffer, error) -> Void in
                        if let e = error {
                            print(e.localizedDescription)
                            return
                        }
                        //convert databuffer to jpeg
                        self.myImageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataBuffer)
                        
                    })
                    
                    self.captureSession.stopRunning()
                    self.confirmAlert()
                }
                
//                // 顔を隠す画像を表示
//                let hideImage = UIImageView(image:UIImage(named:"hoge.jpg"))
//                hideImage.frame = faceRect
                
//                self.hideView.addSubview(hideImage)
            }
        })
    }
    
   
    
    //確認アラート
    func confirmAlert(){
        let alert = UIAlertController(title: "保存しますか？",
                                      message: "",
                                      preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "保存",
                                     style: .Default,
                                     handler: save)
        
        let backAction = UIAlertAction(title: "スタートに戻る",
                                 style: .Default,
                                 handler: back)
        
        let oneMore = UIAlertAction(title: "もう一度",
                                    style: .Cancel,
                                    handler: more)
        alert.addAction(backAction)
        alert.addAction(okAction)
        alert.addAction(oneMore)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    //保存する
    func save(action: UIAlertAction){
        // create UIImage from jpeg
        let myImage = UIImage(data: self.myImageData)!
        // add to album
        UIImageWriteToSavedPhotosAlbum(myImage, self, nil, nil)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    //もう一度
    func more(action: UIAlertAction){
        self.captureSession.startRunning()
    }
    //戻る
    func back(action: UIAlertAction){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
