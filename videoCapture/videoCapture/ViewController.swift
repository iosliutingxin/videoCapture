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
    fileprivate lazy var audioQueue = DispatchQueue.global()
    //协调输入与输出之间传输数据
    fileprivate lazy var session = AVCaptureSession()
    fileprivate var connection : AVCaptureConnection?
    //输出源
    fileprivate var videoOutput : AVCaptureVideoDataOutput?
    fileprivate var audioOutput : AVCaptureAudioDataOutput?

    //相机拍摄预览图层，能实时查看拍照或视频录制效果
    fileprivate lazy var previewlayer = AVCaptureVideoPreviewLayer(session: self.session)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startCapture.addTarget(self, action: #selector(start), for: UIControlEvents.touchDown)
        stopCapture.addTarget(self, action: #selector(stop), for: UIControlEvents.touchDown)
    }

}
//视频、音频的采集
extension ViewController{
    //开始采集
    @objc func start(){
        setVideo()
        setAudio()
        //5、开始采集
        session.startRunning()
    }
    //停止采集
    @objc func stop(){
        print("stop")
        session.stopRunning()
        previewlayer.removeFromSuperlayer()
        session.removeOutput(videoOutput!)
        session.removeOutput(audioOutput!)
        
    }
    func setVideo()  {
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
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.setSampleBufferDelegate(self, queue: videoQueue)
        
        if let outputs = session.outputs as? [AVCaptureVideoDataOutput] {
            for ouput in outputs {
                session.removeOutput(ouput)
            }
        }
        session.addOutput(videoOutput!)
        //4、设置预览层
        previewlayer.frame = view.bounds
        view.layer.insertSublayer(previewlayer, at: 0)
        
       
        
      
    }
    
    //音频采集
    func setAudio() {
        
        //1、获取音频设备
        guard let device = AVCaptureDevice.default(for: .audio) else {
            return
        }
        //2、音频输入源
        guard let audioInput = try? AVCaptureDeviceInput(device : device) else {
            return
        }
        session.addInput(audioInput)
        //3、音频输出
        audioOutput = AVCaptureAudioDataOutput()
        audioOutput!.setSampleBufferDelegate(self, queue: audioQueue)
        session.addOutput(audioOutput!)
        
        //4.设置AVCaptureConnection
        connection = audioOutput!.connection(with: .audio)
     
        
    }
    //切换摄像头
    func swithSceme()  {
        
    }
}

extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate ,AVCaptureAudioDataOutputSampleBufferDelegate{
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if  connection == self.connection {
            print("采集音频数据")
        }else{
            print("采集视频数据")
        }
    }
    
    
}

