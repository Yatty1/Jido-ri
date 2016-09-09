//
//  ViewController.swift
//  faceFeature
//
//  Created by 山田真也 on 2016/08/27.
//  Copyright © 2016年 山田真也. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet var registerBtn: UIButton!
    @IBOutlet var jidoriBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        roundBtn(registerBtn, num: 15.0)
        roundBtn(jidoriBtn, num: 15.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func registerPhoto(){
        performSegueWithIdentifier("takePhoto", sender: nil)
    }

    @IBAction func takeJidori(){
        performSegueWithIdentifier("jidori", sender: nil)
    }
    
    
    //button corner round
    func roundBtn(corner: UIButton, num: CGFloat){
        corner.layer.masksToBounds = true
        corner.layer.cornerRadius = num
    }
    

}

