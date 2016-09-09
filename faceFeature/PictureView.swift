//
//  PictureView.swift
//  faceFeature
//
//  Created by 山田真也 on 2016/09/09.
//  Copyright © 2016年 山田真也. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import CoreImage

//extension UIImage{
//
//    // UIImageをリサイズするメソッド.
//    class func ResizeUIImage(image : UIImage,width : CGFloat, height : CGFloat)-> UIImage!{
//
//        // 指定された画像の大きさのコンテキストを用意.
//        UIGraphicsBeginImageContext(CGSizeMake(width, height))
//
//        // コンテキストに自身に設定された画像を描画する.
//        image.drawInRect(CGRectMake(0, 0, width, height))
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
//}



class PictureView: UIViewController {

    //    var faceAngle: Float = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //        let myImage: UIImage = UIImage.ResizeUIImage(UIImage(named:"IMG_3276.jpg")!, width: self.view.frame.width, height: self.view.frame.height)
    //        // create UIImageView
    //        let myImageView: UIImageView = UIImageView()
    //        myImageView.frame = CGRectMake(0, 0, myImage.size.width, myImage.size.height)
    //        myImageView.image = myImage
    //        self.view.addSubview(myImageView)
    //
    //        //create option as Dictionary Type. add accuracy of recognition
    //        let options: NSDictionary = NSDictionary(object: CIDetectorAccuracyHigh, forKey: CIDetectorAccuracy)
    //
    //        //create CIDetector. type is CIDetectorTypeFace
    //        let detector: CIDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options as! [String : AnyObject])
    //
    //        let faces: NSArray = detector.featuresInImage(CIImage(image: myImage)!)
    //
    //        var transform: CGAffineTransform = CGAffineTransformMakeScale(1, -1)
    //        transform = CGAffineTransformTranslate(transform, 0, -myImageView.bounds.size.height)
    //
    //        var feature : CIFaceFeature = CIFaceFeature()
    //
    //        for feature in faces{
    //            faceAngle = feature.faceAngle
    //               print(faceAngle)
    //            //座標変換
    //            let faceRect: CGRect = CGRectApplyAffineTransform(feature.bounds, transform)
    //            //画像の顔の周りを線で囲うUIVIew
    //            var faceOutline = UIView(frame: faceRect)
    //            faceOutline.layer.borderWidth = 1
    //            faceOutline.layer.borderColor = UIColor.redColor().CGColor
    //            myImageView.addSubview(faceOutline)
    //        }
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
