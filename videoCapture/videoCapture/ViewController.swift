//
//  ViewController.swift
//  videoCapture
//
//  Created by 李孔文 on 2018/3/27.
//  Copyright © 2018年 李孔文. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var startCapture: UIButton!
    @IBOutlet weak var stopCapture: UIButton!
    //普通队列
    fileprivate lazy var videoQueue = DispatchQueue.global()
    fileprivate lazy var session = AVCaptureSession()
    fileprivate lazy var previewlayer = AVCaptureVideoPreviewLayer(session: self.session)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startCapture.addTarget(self, action: #selector(start), for: UIControlEvents.touchDown)
        stopCapture.addTarget(self, action: #selector(stop), for: UIControlEvents.touchDown)
    }

}

extension ViewController{
    //开始采集
    @objc func start(){
        //1、创建捕捉回话
        
        //2、给捕捉会话设置输入源
        //2.1、捕捉摄像头设备
        guard let devices = AVCaptureDevice.devices(for: AVMediaType.video) as? [AVCaptureDevice] else {
            print("摄像头不可用")
            return
        }
        guard let device = devices.filter({$0.position == .front}).first else {
            return
        }
        //2.2、通过device创建avcaptureInput对象
        guard let videoInput = try? AVCaptureDeviceInput(device : device ) else {
            return
        }
        //2.3、将input添加到会话中
        if let inputs = session.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                session.removeInput(input)
            }
        }
        session.addInput(videoInput)
        //3、给捕捉会话设置输出源
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        if let outputs = session.outputs as? [AVCaptureVideoDataOutput] {
            for ouput in outputs {
                session.removeOutput(ouput)
            }
        }
        session.addOutput(videoOutput)
        //4、设置预览层
        previewlayer.frame = view.bounds
        view.layer.insertSublayer(previewlayer, at: 0)
        //5、开始采集
        session.startRunning()
    }
    //停止采集
    @objc func stop(){
        print("stop")
        session.stopRunning()
        previewlayer.removeFromSuperlayer()
    }
}

extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate{
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("开始输出")
    }
}

