//
//  SignalTest.swift
//  SignalDemo
//
//  Created by Razib Chandra Deb on 16/4/20.
//  Copyright © 2020 Razib Chandra Deb. All rights reserved.
//

import Foundation
import ReactiveSwift

func log(_ message: String,
                fileName: String = #file,
                functionName: String = #function,
                lineNumber: Int = #line,
                columnNumber: Int = #column) {
    let fileString: NSString = NSString(string: fileName)
    print("[\(fileString.lastPathComponent)\(functionName)]-\(lineNumber) \(message)")
}

class DownloadTester {
    func testDownloader() {
        
        let manager = DownloadManager()
           
        manager.start().startWithResult { (result) in
            switch result {
            case .success(let progress) :
                print(progress)
                print("[DownloadTester] Download Complete: \(progress)")
            case .failure(let err):
                print(err)
            }
        }
        
        //to test stop downloading
        DispatchQueue.global().async {
            sleep(3)
            manager.stop()
        }
    }
}

protocol DownloaderDelegate {
    func downloadFinished()
    func downloadCanceled()
}

class Downloader {
    var progress: Int
    var shouldStop: Bool
    var delegate: DownloaderDelegate?
    
    init(delegate: DownloaderDelegate) {
        progress = 0
        shouldStop = false
        self.delegate = delegate
    }
    
    func startDownloading() {
         DispatchQueue.global().async {
            //lets say we are donwloading here,
            for index in 0..<10 {
                sleep(1)
                log("[Downloader] Progress \(index*10)%")
                if self.shouldStop {
                    self.delegate?.downloadCanceled()
                    return
                }
            }
            self.delegate?.downloadFinished()
         }
    }
    func stopDownloading() {
        shouldStop = true
    }
}

class DownloadManager {
    
    var observer: Signal<Int, Error>.Observer? = nil
    var lifetime: Lifetime? = nil
    
    var downloader: Downloader?
    func start() -> SignalProducer<Int, Swift.Error> {
        let signalProducer: SignalProducer<Int, Swift.Error> = SignalProducer { (observer, lifetime) in
            //this block won't execute untill someone start this signal
            log("[DownloadManager] Download Starting")
            self.downloader = Downloader(delegate: self)
            self.downloader?.startDownloading()
            
            self.observer = observer
            self.lifetime = lifetime
        }
        return signalProducer
    }
    func stop() {
        log("[DownloadManager] IN")
        self.downloader?.stopDownloading()
        log("[DownloadManager] OUT")
    }
}

extension DownloadManager : DownloaderDelegate {
    func downloadFinished() {
        log("[DownloadManager] IN")
        guard let observer = self.observer else {
            log("[DownloadManager] Error: Observer not found")
            return
        }
        observer.send(value: 100)
        log("[DownloadManager] OUT")
    }
    
    func downloadCanceled() {
        log("[DownloadManager] IN")
        guard let observer = self.observer else {
            log("[DownloadManager] Error: Observer not found")
            return
        }
        observer.send(error: NSError(domain: "Download Cancelled", code: 400, userInfo: nil))
        log("[DownloadManager] OUT")
    }
}

