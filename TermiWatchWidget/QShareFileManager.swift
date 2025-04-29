//
//  QShareFileManager.swift
//  TermiWatchWidget
//
//  Created by Qianlishun on 2024/11/27.
//

import Foundation
import UIKit

extension FileManager{
    
    func makeShareFolderExists(folderName: String) -> URL? {
        let documentsDirectory = FileManager().containerURL(forSecurityApplicationGroupIdentifier: qGroupBundleID)
        guard let folderURL = documentsDirectory?.appendingPathComponent(folderName) else { return nil}
        
        var isDir : ObjCBool = false
        var isExists = FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDir)
        if isExists && !isDir.boolValue {
            do {
                try FileManager.default.removeItem(at: folderURL)
                isExists = false;
            } catch {
                return nil
            }
        }
        if !isExists {
            do {
                try FileManager.default.createDirectory(atPath: folderURL.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
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
                print("文件接收成功，保存到: \(newURL.path)")
                
            } catch {
                print("文件保存失败: \(error.localizedDescription)")
            }

            return newURL.lastPathComponent
        }
        return nil
    }
    
    func saveCutsomWidgetBGImage(image1: Data, image2: Data, oldPath: String?) -> Array<URL>{
        
        let folderName = "image"
      
        if let folderURL = makeShareFolderExists(folderName: folderName){
            let imagename = "qCustomImage" + String(Int.random(in: 1...100))
            
            let imagename1 = imagename+"_1.png"
            let imagename2 = imagename+"_2.png"
            
            let imageURL1 = folderURL.appendingPathComponent(imagename1)
            let imageURL2 = folderURL.appendingPathComponent(imagename2)
            
            var result1 = true
            var result2 = true
            do{ try image1.write(to: imageURL1) }
            catch{ result1 = false }
            do{ try image2.write(to: imageURL2) }
            catch{ result2 = false }
            
            if(result1 && result2){
                
                if(oldPath != nil){
                    let oldURL1 = folderURL.appendingPathComponent(oldPath!+"_1.png")
                    let oldURL2 = folderURL.appendingPathComponent(oldPath!+"_2.png")

                    if(fileExists(atPath: oldURL1.path)){
                        do{ try removeItem(atPath: oldURL1.path)
                        }catch{}
                    }
                    if(fileExists(atPath: oldURL2.path)){
                        do{ try removeItem(atPath: oldURL2.path)
                        }catch{}
                    }
                    
                }
                
                return [imageURL1, imageURL2]
            }
        }
        return Array()
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
                return imageURL.path
            }
        }
        return nil
    }
}
