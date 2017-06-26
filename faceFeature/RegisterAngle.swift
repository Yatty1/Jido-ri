//
//  registerAngle.swift
//  faceFeature
//
//  Created by 山田真也 on 2016/09/09.
//  Copyright © 2016年 山田真也. All rights reserved.
//

import UIKit
import CoreImage

extension UIImage{
    
    // UIImageをリサイズするメソッド.
//    class func ResizeUIImage(_ image : UIImage,width : CGFloat, height : CGFloat)-> UIImage!{
//        
//        // 指定された画像の大きさのコンテキストを用意.
//        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
//        
//        // コンテキストに自身に設定された画像を描画する.
//        image.draw(in: CGRect(x: 0, y: 20, width: width, height: height))
//        
//        // コンテキストからUIImageを作る.
//        let newImage = UIGraphicsGetImageFromCurrentImageContext()
//        
//        // コンテキストを閉じる.
//        UIGraphicsEndImageContext()
//        
//        return newImage
//    }
//    
}


class RegisterAngle: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate{

    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var retake: UIButton!
    @IBOutlet weak var ok: UIButton!
    @IBOutlet weak var angle: UILabel!
    private var faceAngle: Float!

    var defaults: UserDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        retake.layer.masksToBounds = true
        retake.layer.cornerRadius = 15.0
        retake.isHidden = true
        ok.layer.masksToBounds = true
        ok.layer.cornerRadius = 15.0
        ok.isHidden = true
        angle.layer.masksToBounds = true
        angle.layer.cornerRadius = 10.0
        angle.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if myImageView.image == nil{
            chooseAlert()
        }
    }
    
    //デリゲートを設定
    func presentPickerController(_ sourceType: UIImagePickerControllerSourceType){
        if UIImagePickerController.isSourceTypeAvailable(sourceType){
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    //撮影が終わった時のデリゲートメソッド
    func imagePickerController(_ picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!) {
        self.dismiss(animated: true, completion: nil)
        myImageView.image = image
        retake.isHidden = false
        ok.isHidden = false
        angle.isHidden = false
        recognizeFace(myImageView.image!)
    }

    func recognizeFace(_ image: UIImage){
        myImageView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height-170)
        myImageView.image = image
        myImageView.contentMode = UIViewContentMode.scaleAspectFit
        self.view.addSubview(myImageView)
        //create option as Dictionary Type. add accuracy of recognition
        let options: NSDictionary = NSDictionary(object: CIDetectorAccuracyHigh, forKey: CIDetectorAccuracy as NSCopying)
        //create CIDetector. type is CIDetectorTypeFace
        let detector: CIDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options as? [String : AnyObject])!
        let faces: NSArray = detector.features(in: CIImage(image: image)!) as NSArray
        //座標の点をあわせる
        var transform: CGAffineTransform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -myImageView.bounds.size.height)
        faces.forEach { face in
            faceAngle = (face as AnyObject).faceAngle
            angle.text = String(faceAngle)
            faceAngle != 0 ? defaults.set(faceAngle, forKey: "angle") : errorAlert()
            //座標変換
            let faceRect: CGRect = ((face as AnyObject).bounds).applying(transform)
            let faceOutline = UIView(frame: faceRect)
            faceOutline.layer.borderWidth = 1
            faceOutline.layer.borderColor = UIColor.red.cgColor
            myImageView.addSubview(faceOutline)
        }
    }

    @IBAction func okBtn(_ sender: AnyObject) {
        okAlert()
    }

    @IBAction func retakeBtn(_ sender: AnyObject) {
        defaults.removeObject(forKey: "angle")
        retakeAlert()
    }
//MARK: - related to alert
    func errorAlert(){
        let alert = UIAlertController(title: "角度が検知できませんでした。", message: "もう一度撮り直してください", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: camera)
        alert.addAction(action)
        present(alert, animated: true, completion:  nil)
    }

    func okAlert(){
        let alert = UIAlertController(title: "角度を保存しました", message: "", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: okay)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

    func okay(_ action: UIAlertAction){
        self.dismiss(animated: true, completion: nil)
    }

    func chooseAlert(){
        let alert = UIAlertController(title: "写真を選んで角度を登録！", message: "カメラかライブラリから", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "カメラ", style: .default, handler: camera)
        let libraryAction = UIAlertAction(title: "ライブラリ", style: .default, handler: photoLibrary)
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: cancel)
        alert.addAction(cameraAction)
        alert.addAction(libraryAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }

    func retakeAlert(){
        let alert = UIAlertController(title: "写真を選んで角度を登録！", message: "カメラかライブラリから", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "カメラ", style: .default, handler: camera)
        let libraryAction = UIAlertAction(title: "ライブラリ",
                                          style: .default,
                                          handler: { _ in

        })
        let back = UIAlertAction(title: "スタートに戻る", style: .destructive, handler: cancel)
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        alert.addAction(cameraAction)
        alert.addAction(libraryAction)
        alert.addAction(back)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    //MARK: - alert action handler
    func camera (_ action: UIAlertAction){
        self.presentPickerController(.camera)
    }
    func photoLibrary (_ action: UIAlertAction) {
        self.presentPickerController(.photoLibrary)
    }
    func cancel(_ action: UIAlertAction){
        self.dismiss(animated: true, completion: nil)
    }
}
