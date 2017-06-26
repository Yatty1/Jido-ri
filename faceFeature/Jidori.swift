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

    fileprivate var isCaptureEnabled = false
    fileprivate var timer: Timer!
    fileprivate var getCount = 0
    private var timerCount: Int = 4

    fileprivate let captureSession = AVCaptureSession()
    fileprivate var myImageData: Data?
    fileprivate var angle: Float {
        return UserDefaults.standard.float(forKey: "angle")
    }
    private let videoOutput = AVCaptureVideoDataOutput()
    private lazy var photoOutput: AVCapturePhotoOutput = {
        let output = AVCapturePhotoOutput()
        output.isHighResolutionCaptureEnabled = true
        return output
    }()
    fileprivate lazy var videoLayer: AVCaptureVideoPreviewLayer = {
        let layer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        layer.frame = self.view.bounds
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill
        return layer
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

    //MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        captureSession.sessionPreset = AVCaptureSessionPreset1920x1080
        if let device = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) {
            do {
                let videoInput = try AVCaptureDeviceInput.init(device: device)
                captureSession.addInput(videoInput)
            }catch let error as NSError{
                print(error)
            }
        }
        videoOutput.connections
            .flatMap { $0 as? AVCaptureConnection }
            .filter { $0.isVideoOrientationSupported }
            .forEach { $0.videoOrientation = .portrait }
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable : Int(kCVPixelFormatType_32BGRA)]
        setCaptureSession()
        view.layer.addSublayer(videoLayer)
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

    //MARK: - setup
    private func setCaptureSession() {
        let queue: DispatchQueue = DispatchQueue(label: "myqueue", attributes: [])
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        captureSession.addOutput(videoOutput)
        captureSession.addOutput(photoOutput)
    }

    @objc private func back(){
        dismiss(animated: true, completion: nil)
    }

    fileprivate func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage {
        //バッファーをUIImageに変換
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
//        let ciimage = CIImage(cvPixelBuffer: imageBuffer) //simple ver
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer) //common
        let height = CVPixelBufferGetHeight(imageBuffer) //common
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        let imageRef = context?.makeImage()
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
//        let imageRect = CGRect(x: 0, y: 0, width: width, height: height) //simple ver
//        let cgImage = CIContext().createCGImage(ciimage, from: imageRect) //simple ver
//        return UIImage(cgImage: cgImage!)
        let resultImage: UIImage = UIImage(cgImage: imageRef!)
        return resultImage
    }

    private func timerReset() {
        timerCount = 4
    }

    //MARK: - action
    @objc fileprivate func shot(){
        timerLabel.isHidden = false
        timerCount -= 1
        timerLabel.text = String(timerCount)
        if timerCount == 0 {
            let outputSetting = createOutputSetting()
            photoOutput.capturePhoto(with: outputSetting, delegate: self)
            confirmAlert()
            timerLabel.isHidden = true
            timer.invalidate()
        }
    }

    private func createOutputSetting() -> AVCapturePhotoSettings {
        let setting = AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecJPEG])
        setting.flashMode = .auto
        setting.isHighResolutionPhotoEnabled = true
        setting.isAutoStillImageStabilizationEnabled = true
        return setting
    }

//MARK: - related to alert
    private func confirmAlert(){
        let alertView = UIAlertController(title: "保存しますか？", message: "", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "保存", style: .default, handler: save)
        let oneMore = UIAlertAction(title: "もう一度", style: .cancel, handler: onceMore)
        alertView.addAction(okAction)
        alertView.addAction(oneMore)
        isCaptureEnabled = false
        getCount = 0
        present(alertView, animated: true, completion: nil)
    }

    private func save(_ action: UIAlertAction){
        guard let data = myImageData else { return }
        guard let image = UIImage(data: data) else { return }
        UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
        captureSession.stopRunning()
        dismiss(animated: true, completion: nil)
    }

    private func onceMore(_ action: UIAlertAction){
        timerReset()
        captureSession.startRunning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

//MARK: - extends AVCapturePhotoDelegate
extension Jidori: AVCapturePhotoCaptureDelegate {
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        guard let sampleBuffer = photoSampleBuffer else { return }
        myImageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
    }
}

//MARK: - extends AVCaptureVideoDataOutputSampleBufferDelegate
extension Jidori: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        DispatchQueue.main.sync(execute: {
            //バッファーをUIImageに変換
            let image = self.imageFromSampleBuffer(sampleBuffer)
            let ciimage: CIImage = CIImage(image: image)!
            let detector : CIDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options:[CIDetectorAccuracy: CIDetectorAccuracyHigh])!
            let faces : NSArray = detector.features(in: ciimage) as NSArray
            // 検出された顔データを処理
            faces.forEach { face in
                // 座標変換
                var faceRect : CGRect = (face as AnyObject).bounds
                let widthPer = self.view.bounds.width / image.size.width
                let heightPer = self.view.bounds.height / image.size.height
                // UIKitは左上に原点があるが、CoreImageは左下に原点があるので揃える
//                faceRect.origin.y = image.size.height - faceRect.origin.y - faceRect.size.height
                //倍率変換
                faceRect.origin.x = faceRect.origin.x * widthPer
                faceRect.origin.y = faceRect.origin.y * heightPer
                faceRect.size.width = faceRect.size.width * widthPer
                faceRect.size.height = faceRect.size.height * heightPer
                print((face as AnyObject).faceAngle)
                //アングル表示
                angleLabel.text = String((face as AnyObject).faceAngle)
                //指定のアングルで写真を撮る
                isCaptureEnabled = (face as AnyObject).faceAngle == angle
                if isCaptureEnabled {
                    getCount += 1
                    if getCount == 1 {
                        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(shot), userInfo: nil, repeats: true)
                    }
                }
            }
        })
    }
}
