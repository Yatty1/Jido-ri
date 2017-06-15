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
    class func ResizeUIImage(_ image : UIImage,width : CGFloat, height : CGFloat)-> UIImage!{
        
        // 指定された画像の大きさのコンテキストを用意.
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        
        // コンテキストに自身に設定された画像を描画する.
        image.draw(in: CGRect(x: 0, y: 20, width: width, height: height))
        
        // コンテキストからUIImageを作る.
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // コンテキストを閉じる.
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
}


class RegisterAngle: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate{

    @IBOutlet var myImageView: UIImageView!
    //ボタン
    @IBOutlet weak var retake: UIButton!
    @IBOutlet var ok: UIButton!
    var faceAngle: Float!
    
    @IBOutlet weak var angle: UILabel!
    var defaults: UserDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //ぼたんのプロパティ設定
        retake.layer.masksToBounds = true
        retake.layer.cornerRadius = 15.0
        retake.isHidden = true
        ok.layer.masksToBounds = true
        ok.layer.cornerRadius = 15.0
        ok.isHidden = true
        // labelのプロパティ設定
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
        //ここに顔認識、角度取得の処理を書く
        recognizeFace(myImageView.image!)
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func recognizeFace(_ image: UIImage){
        
            let myImage: UIImage = UIImage.ResizeUIImage(image, width: self.view.frame.width, height: self.view.frame.height-147)
            // create UIImageView
            let myImageView: UIImageView = UIImageView()
            myImageView.frame = CGRect(x: 0, y: 0, width: myImage.size.width, height: myImage.size.height)
            myImageView.image = myImage
            myImageView.contentMode = UIViewContentMode.scaleAspectFit
            self.view.addSubview(myImageView)
        
            //create option as Dictionary Type. add accuracy of recognition
            let options: NSDictionary = NSDictionary(object: CIDetectorAccuracyHigh, forKey: CIDetectorAccuracy as NSCopying)
        
            //create CIDetector. type is CIDetectorTypeFace
            let detector: CIDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options as? [String : AnyObject])!
        
            let faces: NSArray = detector.features(in: CIImage(image: myImage)!) as NSArray
        //座標の点をあわせる
            var transform: CGAffineTransform = CGAffineTransform(scaleX: 1, y: -1)
            transform = transform.translatedBy(x: 0, y: -myImageView.bounds.size.height)
        
//            var feature : CIFaceFeature = CIFaceFeature()
        
            for feature in faces{
                faceAngle = (feature as AnyObject).faceAngle
                print("angle is \(faceAngle)")
                if (faceAngle == 0.0){
                    errorAlert()
                    
                }else{
                //userdefaultに保存
                defaults.set(faceAngle, forKey: "angle")
                }
                //labelに表示
                angle.text = String(faceAngle)
                        
                //座標変換
                let faceRect: CGRect = ((feature as AnyObject).bounds).applying(transform)
                //画像の顔の周りを線で囲うUIVIew
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
    
    
    //角度が検知されなかった時のエラーアラート
    func errorAlert(){
        let alert = UIAlertController(title: "角度が検知できませんでした。",
                                      message: "もう一度撮り直してください",
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: "OK",
                                   style: .default,
                                   handler: camera)
        alert.addAction(action)
        present(alert, animated: true, completion:  nil)
    }
    func camera (_ action: UIAlertAction){
        self.presentPickerController(.camera)
    }
    
    //ok押した時のalert
    func okAlert(){
        let alert = UIAlertController(title: "角度を保存しました",
                                      message: "",
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK",
                                     style: .default,
                                     handler: save)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    //ok method
    func save(_ action: UIAlertAction){
        self.dismiss(animated: true, completion: nil)
    }
    
    // 最初に出すアラート。ここでカメラかライブラリかを決める
    func chooseAlert(){
        let alert = UIAlertController(title: "写真を選んで角度を登録！",
                                      message: "カメラかライブラリから",
                                      preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "カメラ",
                                         style: .default){
                                            action in self.presentPickerController(.camera)
        }
        let libraryAction = UIAlertAction(title: "ライブラリ",
                                          style: .default){
                                            action in self.presentPickerController(.photoLibrary)
        }
        let cancelAction = UIAlertAction(title: "キャンセル",
                                         style: .cancel,
                                         handler: cancel)
        alert.addAction(cameraAction)
        alert.addAction(libraryAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    // キャンセルが押された時のメソッド
    func cancel(_ action: UIAlertAction){
        self.dismiss(animated: true, completion: nil)
    }
    
    //リテイクの時のアクションシート。違いはキャンセルを押した時にスタート画面に戻らないこと。
    func retakeAlert(){
        let alert = UIAlertController(title: "写真を選んで角度を登録！",
                                      message: "カメラかライブラリから",
                                      preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "カメラ",
                                         style: .default){
                                            action in self.presentPickerController(.camera)
        }
        let libraryAction = UIAlertAction(title: "ライブラリ",
                                          style: .default){
                                            action in self.presentPickerController(.photoLibrary)
        }
        let back = UIAlertAction(title: "スタートに戻る",
                                 style: .destructive,
                                 handler: cancel)
        let cancelAction = UIAlertAction(title: "キャンセル",
                                         style: .cancel,
                                         handler: nil)
        alert.addAction(cameraAction)
        alert.addAction(libraryAction)
        alert.addAction(back)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }

}
