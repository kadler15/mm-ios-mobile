//
//  CameraViewController.swift
//  MiracleMessages
//
//  Created by Win Raguini on 10/1/16.
//  Copyright © 2016 Win Inc. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import AWSS3

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {

    @IBOutlet weak var playbackView: UIView!

    @IBOutlet weak var previewView: UIView!

    var cameraSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?

    var player: AVPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!

    var isRecording = false

    let videoFileOutput = AVCaptureMovieFileOutput()

    override func viewDidLoad() {
        super.viewDidLoad()

        cameraSession = AVCaptureSession()
        cameraSession!.sessionPreset = AVCaptureSessionPresetHigh

        previewLayer = AVCaptureVideoPreviewLayer(session: cameraSession)
        previewView.layer.addSublayer(previewLayer!)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill

        let rootLayer: CALayer = self.playbackView.layer
        rootLayer.masksToBounds = true

        avPlayerLayer = AVPlayerLayer(player: player)
        avPlayerLayer.bounds = self.playbackView.bounds
        avPlayerLayer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        rootLayer.insertSublayer(avPlayerLayer, at: 0)

        avPlayerLayer.backgroundColor = UIColor.blue.cgColor

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer!.frame = self.previewView.bounds
        let orientation = UIApplication.shared.statusBarOrientation

        switch orientation {
        case .portrait:
            previewLayer?.connection.videoOrientation = .portrait
            break
        case .landscapeRight:
            previewLayer?.connection.videoOrientation = .landscapeRight
            break
        case .landscapeLeft:
            previewLayer?.connection.videoOrientation = .landscapeRight
            break
        case .portraitUpsideDown:
            previewLayer?.connection.videoOrientation = .portrait
            break
        default: break
            previewLayer?.connection.videoOrientation = .portrait
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)


        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)

        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)

            cameraSession?.beginConfiguration() // 1

            if (cameraSession?.canAddInput(deviceInput) == true) {
                cameraSession?.addInput(deviceInput)
            }

            let dataOutput = AVCaptureVideoDataOutput() // 2

            dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)] // 3

            dataOutput.alwaysDiscardsLateVideoFrames = true // 4

            if (cameraSession?.canAddOutput(dataOutput) == true) {
                cameraSession?.addOutput(dataOutput)
            }
            
            cameraSession?.commitConfiguration() //5

            let serialQueue = DispatchQueue(label: "com.invasivecode.queue")
            serialQueue.sync {
            }
            dataOutput.setSampleBufferDelegate(self, queue: serialQueue)
        }
        catch let error as NSError {
            NSLog("\(error), \(error.localizedDescription)")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        cameraSession!.startRunning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPressTakePhoto(_ sender: AnyObject) {
        if isRecording {
            videoFileOutput.stopRecording()
            cameraSession!.stopRunning()
            isRecording = false
        } else {
         cameraSession!.startRunning()
            let recordingDelegate:AVCaptureFileOutputRecordingDelegate? = self

            if cameraSession?.canAddOutput(videoFileOutput) == true {
                cameraSession?.addOutput(videoFileOutput)
            }

            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filePath = documentsURL.appendingPathComponent("temp.mp4")

            videoFileOutput.startRecording(toOutputFileURL: filePath, recordingDelegate: recordingDelegate)
        }


    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */


    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        uploadtoS3(url: outputFileURL)
//        let item = AVPlayerItem(url: outputFileURL)
//        player.replaceCurrentItem(with: item)
//        if (player.currentItem != nil) {
//            print("Starting playback!")
//            player.play()
//        } else {
//            print("Will not start playback")
//        }
//        return
    }

    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        isRecording = true
        return
    }

    func uploadtoS3(url: URL) -> Void {
        let transferManager = AWSS3TransferManager.default()
        let uploadRequest1 : AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()

        uploadRequest1.bucket = "mm-interview-vids"
        uploadRequest1.key =  "bingo"
        uploadRequest1.body = url

        let task = transferManager?.upload(uploadRequest1)
        task?.continue( { (task) -> AnyObject! in
            if task.error != nil {
                print("Error: \(task.error)")
            } else {
                print("Upload successful")
                self.dismiss(animated: true, completion: nil)
            }
            return nil
        })
    }


}
