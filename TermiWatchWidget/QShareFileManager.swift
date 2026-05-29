//
//  QShareFileManager.swift
//  TermiWatchWidget
//
//  Created by Qianlishun on 2024/11/27.
//

import Foundation
import UIKit
import OSLog
import ImageIO

private let shareFileLogger = Logger(subsystem: "com.github.lunf.zShellWatch", category: "ShareFile")
private let maxSharedImageBytes = 2_000_000
private let maxSharedImagePixels = 2_000_000

extension FileManager{
    
    func makeShareFolderExists(folderName: String) -> URL? {
        let documentsDirectory = containerURL(forSecurityApplicationGroupIdentifier: qGroupBundleID)
        guard let folderURL = documentsDirectory?.appendingPathComponent(folderName) else {
            shareFileLogger.error("App Group container unavailable for \(qGroupBundleID, privacy: .public); cannot create shared folder \(folderName, privacy: .public).")
            return nil
        }
        
        var isDir : ObjCBool = false
        var isExists = FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDir)
        if isExists && !isDir.boolValue {
            do {
                try FileManager.default.removeItem(at: folderURL)
                isExists = false;
            } catch {
                shareFileLogger.error("Could not replace shared folder file at \(folderURL.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
                return nil
            }
        }
        if !isExists {
            do {
                try FileManager.default.createDirectory(atPath: folderURL.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                shareFileLogger.error("Could not create shared folder at \(folderURL.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
                return nil
            }
        }
        return folderURL
    }
    
    func saveRecivedImage(srcURL: URL) -> String?{
        let folderName = "image"
      
        if let folderURL = makeShareFolderExists(folderName: folderName){
            
            let newURL = folderURL.appendingPathComponent(srcURL.lastPathComponent)
            
            do {
                if fileExists(atPath: newURL.path) {
                    try removeItem(at: newURL)
                }
                try moveItem(at: srcURL, to: newURL)
                shareFileLogger.info("File received successfully, saved to: \(newURL.path, privacy: .public)")
                
            } catch {
                shareFileLogger.error("File save failed: \(error.localizedDescription, privacy: .public)")
            }

            return newURL.lastPathComponent
        }
        return nil
    }
    
    func saveCutsomWidgetSmallImage(image: Data, oldPath: String?) -> URL?{
        
        let folderName = "image"
      
        if let folderURL = makeShareFolderExists(folderName: folderName){
            let imagename = "qLeftTopImage" + String(Int.random(in: 1...100))
                        
            let imageURL = folderURL.appendingPathComponent(imagename)
            
            var result = true
            do{ try image.write(to: imageURL) }
            catch{ result = false }
            
            if(result){
                
                if(oldPath != nil){
                    let oldURL = folderURL.appendingPathComponent(oldPath!)
                    if(fileExists(atPath: oldURL.path)){
                        do{ try removeItem(atPath: oldURL.path)
                        }catch{}
                    }
                }
                
                return imageURL
            }
        }
        return nil
    }

  
    func getShareImagePath(imageName: String) -> String?{
        let folderName = "image"
        if let folderURL = makeShareFolderExists(folderName: folderName){
            
            let imageURL = folderURL.appendingPathComponent(imageName)
             
            if( fileExists(atPath: imageURL.path) ){
                guard isSafeSharedImage(at: imageURL) else {
                    return nil
                }

                return imageURL.path
            }
        }
        return nil
    }

    private func isSafeSharedImage(at url: URL) -> Bool {
        do {
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = values.fileSize, fileSize > maxSharedImageBytes {
                shareFileLogger.error("Shared image is too large: \(fileSize, privacy: .public) bytes")
                return false
            }
        } catch {
            shareFileLogger.error("Unable to inspect shared image size: \(error.localizedDescription, privacy: .public)")
            return false
        }

        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, options) as? [CFString: Any] else {
            return true
        }

        let width = properties[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = properties[kCGImagePropertyPixelHeight] as? Int ?? 0
        guard width > 0, height > 0 else {
            return true
        }

        if width * height > maxSharedImagePixels {
            shareFileLogger.error("Shared image dimensions are too large: \(width, privacy: .public)x\(height, privacy: .public)")
            return false
        }

        return true
    }
}
