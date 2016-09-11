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
    class func ResizeUIImage(image : UIImage,width : CGFloat, height : CGFloat)-> UIImage!{
        
        // 指定された画像の大きさのコンテキストを用意.
        UIGraphicsBeginImageContext(CGSizeMake(width, height))
        
        // コンテキストに自身に設定された画像を描画する.
        image.drawInRect(CGRectMake(0, 20, width, height))
        
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
    var defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //ぼたんのプロパティ設定
        retake.layer.masksToBounds = true
        retake.layer.cornerRadius = 15.0
        retake.hidden = true
        ok.layer.masksToBounds = true
        ok.layer.cornerRadius = 15.0
        ok.hidden = true
        // labelのプロパティ設定
        angle.layer.masksToBounds = true
        angle.layer.cornerRadius = 10.0
        angle.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        if myImageView.image == nil{
            chooseAlert()
        }
        
    }
    
    //デリゲートを設定
    func presentPickerController(sourceType: UIImagePickerControllerSourceType){
        if UIImagePickerController.isSourceTypeAvailable(sourceType){
            
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.delegate = self
            self.presentViewController(picker, animated: true, completion: nil)
        }
    }
    
    //撮影が終わった時のデリゲートメソッド
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!) {
        self.dismissViewControllerAnimated(true, completion: nil)
        myImageView.image = image
        retake.hidden = false
        ok.hidden = false
        angle.hidden = false
        //ここに顔認識、角度取得の処理を書く
        recognizeFace(myImageView.image!)
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func recognizeFace(image: UIImage){
            let myImage: UIImage = UIImage.ResizeUIImage(image, width: self.view.frame.width, height: self.view.frame.height-145)
            // create UIImageView
            let myImageView: UIImageView = UIImageView()
            myImageView.frame = CGRectMake(0, 0, myImage.size.width, myImage.size.height)
            myImageView.image = myImage
            myImageView.contentMode = UIViewContentMode.ScaleAspectFit
            self.view.addSubview(myImageView)
        
            //create option as Dictionary Type. add accuracy of recognition
            let options: NSDictionary = NSDictionary(object: CIDetectorAccuracyHigh, forKey: CIDetectorAccuracy)
        
            //create CIDetector. type is CIDetectorTypeFace
            let detector: CIDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options as? [String : AnyObject])
        
            let faces: NSArray = detector.featuresInImage(CIImage(image: myImage)!)
        
            var transform: CGAffineTransform = CGAffineTransformMakeScale(1, -1)
            transform = CGAffineTransformTranslate(transform, 0, -myImageView.bounds.size.height)
        
            var feature : CIFaceFeature = CIFaceFeature()
        
            for feature in faces{
                faceAngle = feature.faceAngle
                print("angle is \(faceAngle)")
                if (faceAngle == 0.0){
                    errorAlert()
                    
                }else{
                //userdefaultに保存
                defaults.setFloat(faceAngle, forKey: "angle")
                }
                //labelに表示
                angle.text = String(faceAngle)
                        
                //座標変換
                let faceRect: CGRect = CGRectApplyAffineTransform(feature.bounds, transform)
                //画像の顔の周りを線で囲うUIVIew
                var faceOutline = UIView(frame: faceRect)
                faceOutline.layer.borderWidth = 1
                faceOutline.layer.borderColor = UIColor.redColor().CGColor
                myImageView.addSubview(faceOutline)
            }
            

    }
    
    @IBAction func okBtn(sender: AnyObject) {
        okAlert()
    }
    
    @IBAction func retakeBtn(sender: AnyObject) {
        defaults.removeObjectForKey("angle")
        retakeAlert()
    }
    
    
    //角度が検知されなかった時のエラーアラート
    func errorAlert(){
        let alert = UIAlertController(title: "角度が検知できませんでした。",
                                      message: "もう一度撮り直してください",
                                      preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK",
                                   style: .Default,
                                   handler: camera)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion:  nil)
    }
    func camera (action: UIAlertAction){
        self.presentPickerController(.Camera)
    }
    
    //ok押した時のalert
    func okAlert(){
        let alert = UIAlertController(title: "角度を保存しました",
                                      message: "",
                                      preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK",
                                     style: .Default,
                                     handler: save)
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    //ok method
    func save(action: UIAlertAction){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // 最初に出すアラート。ここでカメラかライブラリかを決める
    func chooseAlert(){
        let alert = UIAlertController(title: "写真を選んで角度を登録！",
                                      message: "カメラかライブラリから",
                                      preferredStyle: .ActionSheet)
        let cameraAction = UIAlertAction(title: "カメラ",
                                         style: .Default){
                                            action in self.presentPickerController(.Camera)
        }
        let libraryAction = UIAlertAction(title: "ライブラリ",
                                          style: .Default){
                                            action in self.presentPickerController(.PhotoLibrary)
        }
        let cancelAction = UIAlertAction(title: "キャンセル",
                                         style: .Cancel,
                                         handler: cancel)
        alert.addAction(cameraAction)
        alert.addAction(libraryAction)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    // キャンセルが押された時のメソッド
    func cancel(action: UIAlertAction){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //リテイクの時のアクションシート。違いはキャンセルを押した時にスタート画面に戻らないこと。
    func retakeAlert(){
        let alert = UIAlertController(title: "写真を選んで角度を登録！",
                                      message: "カメラかライブラリから",
                                      preferredStyle: .ActionSheet)
        let cameraAction = UIAlertAction(title: "カメラ",
                                         style: .Default){
                                            action in self.presentPickerController(.Camera)
        }
        let libraryAction = UIAlertAction(title: "ライブラリ",
                                          style: .Default){
                                            action in self.presentPickerController(.PhotoLibrary)
        }
        let back = UIAlertAction(title: "スタートに戻る",
                                 style: .Destructive,
                                 handler: cancel)
        let cancelAction = UIAlertAction(title: "キャンセル",
                                         style: .Cancel,
                                         handler: nil)
        alert.addAction(cameraAction)
        alert.addAction(libraryAction)
        alert.addAction(back)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
    }

}
