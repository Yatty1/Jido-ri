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
    let videoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    //mydevice
    var myDevice: AVCaptureDevice!
    //get device list
    let devices = AVCaptureDevice.devices()
    
    var videoOutput = AVCaptureVideoDataOutput()
    var imageOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
    var myImageData: Data!

    
    var hideView = UIView()
    
    var capturedImage: UIImage!
    
    var defaults: UserDefaults = UserDefaults.standard
    var angle: Float!

    //label
    var angleLabel : UILabel!
    var backBtn: UIButton!
    
    //timer
    var timer: Int = 4
    var timerLabel: UILabel!
    var getCount: Int = 0
    var timerCount: Timer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //angle label
        angleLabel = UILabel(frame: CGRect(x: 0,y: 0,width: 100,height: 50))
        angleLabel.backgroundColor = UIColor.cyan
        angleLabel.textColor = UIColor.white
        angleLabel.textAlignment = NSTextAlignment.center
        angleLabel.layer.masksToBounds = true
        angleLabel.layer.cornerRadius = 20.0
        angleLabel.layer.position = CGPoint(x:self.view.bounds.width/2, y: self.view.bounds.height-620)
        
        //backBtn
        backBtn = UIButton(frame: CGRect(x: 0,y: 0,width: 100,height: 50))
        backBtn.backgroundColor = UIColor.orange
        backBtn.setTitle("Back", for: UIControlState())
        backBtn.setTitleColor(UIColor.white, for: UIControlState())
        backBtn.layer.masksToBounds = true
        backBtn.layer.cornerRadius = 10.0
        backBtn.layer.position = CGPoint(x:self.view.bounds.width-300, y: self.view.bounds.height-50)
        backBtn.addTarget(self, action: #selector(back), for: .touchUpInside)
        
        //timer label
        timerLabel = UILabel(frame: CGRect(x: 0,y: 0,width: 80, height: 150))
        timerLabel.textColor = UIColor.white
        timerLabel.textAlignment = NSTextAlignment.center
        timerLabel.font = timerLabel.font.withSize(40)
        timerLabel.layer.position = CGPoint(x:self.view.bounds.width/2, y:self.view.bounds.height-300)
        timerLabel.isHidden = true
        
        //get front camera
        for device in devices!{
            if ((device as AnyObject).position == AVCaptureDevicePosition.front){
                myDevice = device as! AVCaptureDevice
            }
        }
        
        do {
            let videoInput = try! AVCaptureDeviceInput.init(device: myDevice)
            self.captureSession.addInput(videoInput)
        }catch let error as NSError{
            print(error)
        }
        //?????
        self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable : Int(kCVPixelFormatType_32BGRA)]
        
        //フレームごとに呼び出すデリゲート登録  ?????
        let queue: DispatchQueue = DispatchQueue(label: "myqueue", attributes: []);
        self.videoOutput.setSampleBufferDelegate(self, queue: queue)
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        
        self.captureSession.addOutput(self.videoOutput)
        self.captureSession.addOutput(self.imageOutput)
        
        let videoLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.view.layer.addSublayer(videoLayer)
        
        //カメラの向き
        videoOutput.connections
            .flatMap { $0 as? AVCaptureConnection }
            .filter{ $0.isVideoOrientationSupported }
            .forEach { $0.videoOrientation = AVCaptureVideoOrientation.portrait }
        
        hideView = UIView(frame: self.view.bounds)
        self.view.addSubview(hideView)
        self.view.addSubview(angleLabel)
        self.view.addSubview(backBtn)
        self.view.addSubview(timerLabel)
        self.captureSession.startRunning()
    }
    
    
    
    func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage {
        //バッファーをUIImageに変換
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        let imageRef = context?.makeImage()
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        let resultImage: UIImage = UIImage(cgImage: imageRef!)
        return resultImage
    }
    
    
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        //同期処理（非同期処理ではキューが溜まりすぎて画像がついていかない）
        DispatchQueue.main.sync(execute: {
            
            //バッファーをUIImageに変換
            let image = self.imageFromSampleBuffer(sampleBuffer)
            
            let ciimage:CIImage! = CIImage(image: image)
            
            //CIDetectorAccuracyHighだと高精度（使った感じは遠距離による判定の精度）だが処理が遅くなる
            let detector : CIDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options:[CIDetectorAccuracy: CIDetectorAccuracyLow] )!
            let faces : NSArray = detector.features(in: ciimage) as NSArray
            
            // 検出された顔データを処理
            for subview:UIView in self.hideView.subviews  {
                subview.removeFromSuperview()
            }
            
//            var feature : CIFaceFeature = CIFaceFeature()
            
            for feature in faces {
                
                // 座標変換
                var faceRect : CGRect = (feature as AnyObject).bounds
                let widthPer = (self.view.bounds.width/image.size.width)
                let heightPer = (self.view.bounds.height/image.size.height)
                
                // UIKitは左上に原点があるが、CoreImageは左下に原点があるので揃える
                faceRect.origin.y = image.size.height - faceRect.origin.y - faceRect.size.height
                
                //倍率変換
                faceRect.origin.x = faceRect.origin.x * widthPer
                faceRect.origin.y = faceRect.origin.y * heightPer
                faceRect.size.width = faceRect.size.width * widthPer
                faceRect.size.height = faceRect.size.height * heightPer
                
                print((feature as AnyObject).faceAngle)
                //アングル表示
                self.angleLabel.text = String((feature as AnyObject).faceAngle)
                self.angle = self.defaults.float(forKey: "angle")
                
                //指定のアングルで写真を撮る
                if ((feature as AnyObject).faceAngle == self.angle){
                    
                    self.getCount += 1
                    if (self.getCount == 1){
                        self.timerCount = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.shot), userInfo: nil, repeats: true)
                    }
                }
            }
        })
    }
    
   
    
    //確認アラート
    func confirmAlert(){
        let alert = UIAlertController(title: "保存しますか？",
                                      message: "",
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "保存",
                                     style: .default,
                                     handler: save)
        let oneMore = UIAlertAction(title: "もう一度",
                                    style: .cancel,
                                    handler: more)
        alert.addAction(okAction)
        alert.addAction(oneMore)
        self.getCount = 0
        present(alert, animated: true, completion: nil)
    }
    //タイマーで呼び出し。　3.2.1でシャッターを切る
    func shot(){
        
        timerLabel.isHidden = false
        timer = timer - 1
        timerLabel.text = String(timer)
        
        if timer == 0{
            //シャッターを押す
            //connect video output
            let myVideoConnection = self.imageOutput.connection(withMediaType: AVMediaTypeVideo)
            //get image from connection
            self.imageOutput.captureStillImageAsynchronously(from: myVideoConnection, completionHandler: {(imageDataBuffer, error) -> Void in
                if let e = error {
                    print(e.localizedDescription)
                    return
                }
                //temporarily savee photo image to [imageDataBuffer]
                //convert databuffer to jpeg
                self.myImageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataBuffer)
            })
            
            self.captureSession.stopRunning()
            self.confirmAlert()
            //タイマーを止める。タイマーリセット
            timerCount.invalidate()
            timer = 4
            timerLabel.isHidden = true
        }
    }
    
    //保存する
    func save(_ action: UIAlertAction){
        // create UIImage from jpeg
        let myImage = UIImage(data: self.myImageData)!
        // add to album
        UIImageWriteToSavedPhotosAlbum(myImage, self, nil, nil)
        self.captureSession.stopRunning()
        self.dismiss(animated: true, completion: nil)
    }
    //もう一度
    func more(_ action: UIAlertAction){
        self.captureSession.startRunning()
    }
    func back(){
        self.captureSession.stopRunning()
        self.dismiss(animated: true, completion: nil)
    }
      
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
