//
//  ViewController.swift
//  videoCapture
//
//  Created by 李孔文 on 2018/3/27.
//  Copyright © 2018年 李孔文. All rights reserved.
//

import UIKit
import AVFoundation
import GPUImage

class ViewController: UIViewController {
    @IBOutlet weak var startCapture: UIButton!
    @IBOutlet weak var stopCapture: UIButton!
    @IBOutlet weak var Sceme: UIButton!
    @IBOutlet weak var simpleBeauty: UIButton!
    @IBOutlet weak var filterBeauty: UIButton!
    @IBOutlet weak var brightnesSlider: UISlider!
    @IBOutlet weak var bilateralSiler: UISlider!
    //普通队列
    fileprivate lazy var videoQueue = DispatchQueue.global()
    fileprivate lazy var audioQueue = DispatchQueue.global()
    //协调输入与输出之间传输数据
    fileprivate lazy var session = AVCaptureSession()
    fileprivate var connection : AVCaptureConnection?
    //输入源
    fileprivate var videoInput : AVCaptureDeviceInput?
    //输出源
    fileprivate var videoOutput : AVCaptureVideoDataOutput?
    fileprivate var audioOutput : AVCaptureAudioDataOutput?
    //相机拍摄预览图层，能实时查看拍照或视频录制效果
    fileprivate lazy var previewlayer = AVCaptureVideoPreviewLayer(session: self.session)
    
    
    //美颜
    fileprivate var videoCamera : GPUImageVideoCamera?
    fileprivate var bilateralFilter : GPUImageBilateralFilter?
    fileprivate var brightnessFilter : GPUImageBrightnessFilter?

    override func viewDidLoad() {
        super.viewDidLoad()
        startCapture.addTarget(self, action: #selector(start), for: UIControlEvents.touchDown)
        stopCapture.addTarget(self, action: #selector(stop), for: UIControlEvents.touchDown)
        Sceme.addTarget(self, action: #selector(swithSceme), for: UIControlEvents.touchDown)
        simpleBeauty.addTarget(self, action: #selector(simpleAction), for: UIControlEvents.touchDown)
        
        brightnesSlider.addTarget(self, action:#selector(brightnessFilterAction(sender:)), for: UIControlEvents.touchUpInside)
        bilateralSiler.addTarget(self, action: #selector(bilateralFilterAction(sender:)), for: UIControlEvents.touchUpInside)
    }

}
//视频、音频的采集
extension ViewController{
    //开始采集
    @objc func start(){
        print("begin")
        guard !session.isRunning else {
            return
        }
        setVideo()
        setAudio()
        session.startRunning()
        
    }
    //停止采集
    @objc func stop(){
        print("stop")
        guard session.isRunning else {
            return
        }
        session.stopRunning()
        previewlayer.removeFromSuperlayer()
        session.removeOutput(videoOutput!)
        session.removeOutput(audioOutput!)
   
        
    }
    //切换摄像头
    @objc func swithSceme()  {
        setSeceme()
    }
}

//-----------------------------------------视频采集---------------------------------------------
extension ViewController{
    //视频设置
    func setVideo()  {
        //1、创建捕捉回话
        
        //2、给捕捉会话设置输入源
        //2.1、捕捉摄像头设备
        guard let devices = AVCaptureDevice.devices(for: AVMediaType.video) as? [AVCaptureDevice] else {
            print("摄像头不可用")
            return
        }
        guard let device = devices.filter({$0.position == .back}).first else {
            return
        }
        //2.2、通过device创建avcaptureInput对象
        guard var videoInput = try? AVCaptureDeviceInput(device : device ) else {
            return
        }
        //2.3、将input添加到会话中
        if let inputs = session.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                
                session.removeInput(input)
            }
        }
        self.videoInput = videoInput
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
}
//-------------------------------------音频采集---------------------------------------------------
extension ViewController{

    //音频设置
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
}
//---------------------------------------摄像头切换-----------------------------------------
extension ViewController{
    func setSeceme(){
        // 1:获取之前的镜头
        guard var position = videoInput?.device.position else { return }
        
        // 2:获取当前显示的镜头
        position = position == .front ? .back : .front
        
        // 3:根据当前镜头创建新的device
        let devices = AVCaptureDevice.devices(for: AVMediaType.video) as? [AVCaptureDevice]
        guard let device = devices?.filter({$0.position == position}).first else { return }
        
        // 4: 根据新的device创建新的input
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else { return }
        
        // 4:在session中切换input
        session.beginConfiguration()
        session.removeInput(self.videoInput!)
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        session.commitConfiguration()
        self.videoInput = videoInput
    
        
    }
}
//输出源代理
extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate ,AVCaptureAudioDataOutputSampleBufferDelegate{
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if  connection == self.connection {
            print("采集音频数据")
        }else{
            print("采集视频数据")
        }
    }
    
}

//GPUImage原生美颜
extension ViewController {
    
    @objc func simpleAction()  {

        // 创建视频源
        // SessionPreset:屏幕分辨率，AVCaptureSessionPresetHigh会自适应高分辨率
        // cameraPosition:摄像头方向
        let videoCamera = GPUImageVideoCamera.init(sessionPreset:AVCaptureSession.Preset.high.rawValue , cameraPosition: .front)
        videoCamera?.outputImageOrientation = .portrait
        self.videoCamera = videoCamera;
        // 创建最终预览View
        let captureVideoPreview = GPUImageView(frame: self.view.bounds)
        view.insertSubview(captureVideoPreview, at: 0)
        // 创建滤镜：磨皮，美白，组合滤镜
        let groupFilter = GPUImageFilterGroup()
        // 磨皮滤镜
        let bilateralFilter = GPUImageBilateralFilter()
        groupFilter.addTarget(bilateralFilter)
        self.bilateralFilter = bilateralFilter
        // 美白滤镜
        let brightnessFilter = GPUImageBrightnessFilter()
        groupFilter.addTarget(brightnessFilter)
        self.brightnessFilter = brightnessFilter;
        // 设置滤镜组链
        bilateralFilter.addTarget(brightnessFilter)
        groupFilter.initialFilters = [bilateralFilter]
        groupFilter.terminalFilter = brightnessFilter
        // 设置GPUImage响应链，从数据源 => 滤镜 => 最终界面效果
        videoCamera?.addTarget(groupFilter)
        groupFilter.addTarget(captureVideoPreview)
     
        // 必须调用startCameraCapture，底层才会把采集到的视频源，渲染到GPUImageView中，就能显示了。
        // 开始采集视频
        videoCamera?.startCapture()
    }
    

    
    @objc func brightnessFilterAction(sender :UISlider ) {
        brightnessFilter?.brightness = CGFloat(sender.value)

    }
 
    @objc func bilateralFilterAction(sender:UISlider)  {
        // 值越小，磨皮效果越好
        let maxValue : CGFloat = 10;
        bilateralFilter?.distanceNormalizationFactor = maxValue - CGFloat(sender.value)
    }
 
    
}

