//
//  Jidori.swift
//  faceFeature
//
//  Created by 山田真也 on 2016/09/09.
//  Copyright © 2016年 山田真也. All rights reserved.
//

import UIKit
import AVFoundation

class Jidori: UIViewController {

    let captureSession = AVCaptureSession()
    var myImageData: Data?
    let userDefaults: UserDefaults = UserDefaults.standard
    var angle: Float!
    private let videoOutput = AVCaptureVideoDataOutput()
    private lazy var photoOutput: AVCapturePhotoOutput = {
        let output = AVCapturePhotoOutput()
        output.isHighResolutionCaptureEnabled = true
        return output
    }()
    private lazy var outPutSetting: AVCapturePhotoSettings = {
        let setting = AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecJPEG])
        setting.flashMode = .auto
        setting.isHighResolutionPhotoEnabled = true
        setting.isAutoStillImageStabilizationEnabled = true
        return setting
    }()
    fileprivate lazy var videoLayer: AVCaptureVideoPreviewLayer = {
        let layer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        layer.frame = self.view.bounds
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill
        return layer
    }()
    fileprivate lazy var hideView: UIView = {
        return UIView(frame: self.view.bounds)
    }()
    fileprivate lazy var angleLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0,y: 0,width: 100,height: 50))
        label.backgroundColor = .cyan
        label.textColor = .white
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 20.0
        label.layer.position = CGPoint(x:self.view.bounds.width/2, y: self.view.bounds.height-620)
        return label
    }()
    private lazy var backBtn: UIButton = {
        let button = UIButton(frame: CGRect(x: 0,y: 0,width: 100,height: 50))
        button.backgroundColor = .orange
        button.setTitle("Back", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 10.0
        button.layer.position = CGPoint(x: self.view.bounds.width-300, y: self.view.bounds.height-50)
        button.addTarget(self, action: #selector(back), for: .touchUpInside)
        return button
    }()
    private lazy var timerLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0,y: 0,width: 80, height: 150))
        label.textColor = .white
        label.textAlignment = .center
        label.font = label.font.withSize(40)
        label.layer.position = CGPoint(x:self.view.bounds.width/2, y:self.view.bounds.height-300)
        label.isHidden = true
        return label
    }()

    var timer: Int = 4
    var getCount: Int = 0
    var timerCount: Timer!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let device = AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDeviceType.builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) {
            do {
                let videoInput = try AVCaptureDeviceInput.init(device: device)
                captureSession.addInput(videoInput)
            }catch let error as NSError{
                print(error)
            }
        }

        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable : Int(kCVPixelFormatType_32BGRA)]
        setCaptureSession()
        videoOutput.connections
            .flatMap { $0 as? AVCaptureConnection }
            .filter{ $0.isVideoOrientationSupported }
            .forEach { $0.videoOrientation = AVCaptureVideoOrientation.portrait }
        view.layer.addSublayer(videoLayer)
//        view.addSubview(hideView)
        view.addSubview(angleLabel)
        view.addSubview(backBtn)
        view.addSubview(timerLabel)
    }

    override func viewWillAppear(_ animated: Bool) {
        captureSession.startRunning()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession.stopRunning()
    }

    private func setCaptureSession() {
        let queue: DispatchQueue = DispatchQueue(label: "myqueue", attributes: [])
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        captureSession.addOutput(videoOutput)
        captureSession.addOutput(photoOutput)
    }

    fileprivate func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage {
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

    //確認アラート
    private func confirmAlert(){
        let alertView = UIAlertController(title: "保存しますか？", message: "", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "保存", style: .default, handler: save)
        let oneMore = UIAlertAction(title: "もう一度", style: .cancel, handler: onceMore)
        alertView.addAction(okAction)
        alertView.addAction(oneMore)
        getCount = 0
        present(alertView, animated: true, completion: nil)
    }

    //タイマーで呼び出し。　3.2.1でシャッターを切る
    @objc fileprivate func shot(){
        timerLabel.isHidden = false
        timer -= 1
        timerLabel.text = String(timer)
        if timer == 0 {
            print(outPutSetting)
            if let connection = photoOutput.connection(withMediaType: AVMediaTypeVideo) {
                connection.videoOrientation = videoLayer.connection.videoOrientation
            }
            photoOutput.capturePhoto(with: outPutSetting, delegate: self)
            captureSession.stopRunning()
            confirmAlert()
            //タイマーを止める。タイマーリセット
            timerCount.invalidate()
            timer = 4
            timerLabel.isHidden = true
        }
    }

    //保存する
    private func save(_ action: UIAlertAction){
        // create UIImage from jpeg
        guard let data = myImageData else { return }
        guard let image = UIImage(data: data) else { return }
        // add to album
        UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
        captureSession.stopRunning()
        dismiss(animated: true, completion: nil)
    }

    //もう一度
    private func onceMore(_ action: UIAlertAction){
        captureSession.startRunning()
    }

    @objc private func back(){
        dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension Jidori: AVCapturePhotoCaptureDelegate {

    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        print(photoSampleBuffer)
        print(previewPhotoSampleBuffer)
        guard let sampleBuffer = photoSampleBuffer else { return }
        myImageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
    }
}

extension Jidori: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        DispatchQueue.main.sync(execute: {
            //バッファーをUIImageに変換
            let image = self.imageFromSampleBuffer(sampleBuffer)
            let ciimage: CIImage = CIImage(image: image)!
            //CIDetectorAccuracyHighだと高精度（使った感じは遠距離による判定の精度）だが処理が遅くなる
            let detector : CIDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options:[CIDetectorAccuracy: CIDetectorAccuracyHigh] )!
            let faces : NSArray = detector.features(in: ciimage) as NSArray
            // 検出された顔データを処理
            hideView.subviews.forEach { $0.removeFromSuperview() }
            faces.forEach { face in
                // 座標変換
                var faceRect : CGRect = (face as AnyObject).bounds
                let widthPer = (self.view.bounds.width/image.size.width)
                let heightPer = (self.view.bounds.height/image.size.height)
                // UIKitは左上に原点があるが、CoreImageは左下に原点があるので揃える
                faceRect.origin.y = image.size.height - faceRect.origin.y - faceRect.size.height
                //倍率変換
                faceRect.origin.x = faceRect.origin.x * widthPer
                faceRect.origin.y = faceRect.origin.y * heightPer
                faceRect.size.width = faceRect.size.width * widthPer
                faceRect.size.height = faceRect.size.height * heightPer
                print((face as AnyObject).faceAngle)
                //アングル表示
                angleLabel.text = String((face as AnyObject).faceAngle)
                angle = userDefaults.float(forKey: "angle")
                //指定のアングルで写真を撮る
                if (face as AnyObject).faceAngle == angle {
                    getCount += 1
                    if (getCount == 1){
                        timerCount = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(shot), userInfo: nil, repeats: true)
                    }
                }
            }
        })
    }
}
