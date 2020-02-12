//
//  LivePhotoCaptureDelegate.swift
//  iOS-10-Sampler
//
//  Created by Shuichi Tsutsumi on 9/5/16.
//  Copyright © 2016 Shuichi Tsutsumi. All rights reserved.
//
//  [Reference] This sample is based on the Apple's sample "AVCam-iOS".

import AVFoundation
import Photos

class LivePhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    
    private(set) var requestedPhotoSettings: AVCapturePhotoSettings
    private let capturingLivePhoto: (Bool) -> ()
    private let completed: (LivePhotoCaptureDelegate) -> ()
    private var photoData: Data? = nil
    private var livePhotoCompanionMovieURL: URL? = nil
    
    init(with requestedPhotoSettings: AVCapturePhotoSettings, capturingLivePhoto: @escaping (Bool) -> (), completed: @escaping (LivePhotoCaptureDelegate) -> ()) {
        self.requestedPhotoSettings = requestedPhotoSettings
        self.capturingLivePhoto = capturingLivePhoto
        self.completed = completed
    }
    
    private func save(photoData: Data) {
        PHPhotoLibrary.shared().performChanges({ [unowned self] in
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: photoData, options: nil)
            
            if let livePhotoCompanionMovieURL = self.livePhotoCompanionMovieURL {
                let livePhotoCompanionMovieFileResourceOptions = PHAssetResourceCreationOptions()
                livePhotoCompanionMovieFileResourceOptions.shouldMoveFile = true
                creationRequest.addResource(with: .pairedVideo, fileURL: livePhotoCompanionMovieURL, options: livePhotoCompanionMovieFileResourceOptions)
            }
            
            }, completionHandler: { [unowned self] success, error in
                if let error = error {
                    print("Error occurered while saving photo to photo library: \(error)")
                }
                
                self.didFinish()
            }
        )
    }
    
    private func didFinish() {
        if let livePhotoCompanionMoviePath = livePhotoCompanionMovieURL?.path {
            if FileManager.default.fileExists(atPath: livePhotoCompanionMoviePath) {
                do {
                    try FileManager.default.removeItem(atPath: livePhotoCompanionMoviePath)
                }
                catch {
                    print("Could not remove file at url: \(livePhotoCompanionMoviePath)")
                }
            }
        }
        
        completed(self)
    }
    
    // =========================================================================
    // MARK: - AVCapturePhotoCaptureDelegate
    
    func capture(_ captureOutput: AVCapturePhotoOutput, willBeginCaptureForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings) {
        if resolvedSettings.livePhotoMovieDimensions.width > 0 && resolvedSettings.livePhotoMovieDimensions.height > 0 {
            capturingLivePhoto(true)
        }
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let photoSampleBuffer = photoSampleBuffer {
            photoData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
        }
        else {
            print("Error capturing photo: \(error)")
            return
        }
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL, resolvedSettings: AVCaptureResolvedPhotoSettings) {
        capturingLivePhoto(false)
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplay photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let _ = error {
            print("Error processing live photo companion movie: \(error)")
            return
        }
        
        livePhotoCompanionMovieURL = outputFileURL
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishCaptureForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            didFinish()
            return
        }
        
        guard let photoData = photoData else {
            print("No photo data resource")
            didFinish()
            return
        }
        
        PHPhotoLibrary.requestAuthorization { [unowned self] status in
            if status == .authorized {
                self.save(photoData: photoData)
            }
            else {
                self.didFinish()
            }
        }
    }
}
