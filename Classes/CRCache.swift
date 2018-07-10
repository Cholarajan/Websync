//
//  CRCache.swift
//  ApicallSample
//
//  Created by chola on 7/5/18.
//  Copyright © 2018 chola. All rights reserved.
//

import UIKit

extension Dictionary {
    func keysSortedByValue(_ isOrderedBefore: (Value, Value) -> Bool) -> [Key] {
        return Array(self).sorted{ isOrderedBefore($0.1, $1.1) }.map{ $0.0 }
    }
}

public class CRCache {
    
    static let defaultCachePeriodInSec: TimeInterval = 60 * 60 * 24 * 2 // 2 days
    
    var cachePath: String
    
    let ioQueue: DispatchQueue
    
    let fileManager: FileManager
    
    /// Life time of disk cache, in second.
    open var cachePeriodInSecond = CRCache.defaultCachePeriodInSec
    
    /// In byte. 0 mean no limit.
    open var maxCacheSize: UInt = 0
    
    init() {
        
        let bundleIdentifier = Bundle.main.bundleIdentifier
        let cacheDirectory = bundleIdentifier! + ".cache.default"
        let ioqueue_label = bundleIdentifier! + ".queue.default"
        
        cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
        cachePath = (cachePath as NSString).appendingPathComponent(cacheDirectory)
        
        ioQueue = DispatchQueue(label: ioqueue_label)
        
        self.fileManager = FileManager()
        
        #if !os(OSX) && !os(watchOS)
            NotificationCenter.default.addObserver(self, selector: #selector(CRCache.cleanExpiredCache), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(CRCache.cleanExpiredCache), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        #endif
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: Store data

extension CRCache {
    
    /// Write data for key. This is an async operation.
    func write(data: Data, forKey key: String) {
        writeDataToDisk(data: data, key: key)
    }
    
    func writeDataToDisk(data: Data, key: String) {
        ioQueue.async {
            if self.fileManager.fileExists(atPath: self.cachePath) == false {
                do {
                    try self.fileManager.createDirectory(atPath: self.cachePath, withIntermediateDirectories: true, attributes: nil)
                }
                catch {
                    print("Error while creating cache folder")
                }
            }
            
            self.fileManager.createFile(atPath: self.cachePath(forKey: key), contents: data, attributes: nil)
        }
    }
    
    /// Read data for key
    func read(forKey key:String) -> Data? {
        var data: Data!
        
            if let dataFromDisk = readDataFromDisk(forKey: key) {
                data = dataFromDisk
            }
        
        return data
    }
    
    /// Read data from disk for key
    func readDataFromDisk(forKey key: String) -> Data? {
        return self.fileManager.contents(atPath: cachePath(forKey: key))
    }
    
    // MARK: Utils
    /// Check if has data on disk
    func hasDataOnDiskForKey(key: String) -> Bool {
        return self.fileManager.fileExists(atPath: self.cachePath(forKey: key))
    }
    
    // MARK: Clean
    /// Clean all mem cache and disk cache.
    func cleanAll() {
        cleanCache()
    }
    
    /// Clean cache by key.
    func clean(byKey key: String) {
        
        ioQueue.async {
            do {
                try self.fileManager.removeItem(atPath: self.cachePath(forKey: key))
            } catch {}
        }
    }
    
    func cleanCache() {
        ioQueue.async {
            do {
                try self.fileManager.removeItem(atPath: self.cachePath)
            } catch {}
        }
    }
    
    /// Clean expired disk cache. This is an async operation.
    @objc func cleanExpiredCache() {
        cleanExpiredCache(completion: nil)
    }
    
    // This method from Kingfisher
    // Clean expired disk cache with completionHandler.
    open func cleanExpiredCache(completion handler: (()->())? = nil) {
        
        // Do things in cocurrent io queue
        ioQueue.async {
            
            var (URLsToDelete, CacheSize, cachedFiles) = self.travelCachedFiles(onlyForCacheSize: false)
            
            for fileURL in URLsToDelete {
                do {
                    try self.fileManager.removeItem(at: fileURL)
                } catch _ { }
            }
            
            if self.maxCacheSize > 0 && CacheSize > self.maxCacheSize {
                let targetSize = self.maxCacheSize / 2
                
                // Sort files by last modify date. We want to clean from the oldest files.
                let sortedFiles = cachedFiles.keysSortedByValue {
                    resourceValue1, resourceValue2 -> Bool in
                    
                    if let date1 = resourceValue1.contentAccessDate,
                        let date2 = resourceValue2.contentAccessDate
                    {
                        return date1.compare(date2) == .orderedAscending
                    }
                    
                    // Not valid date information. This should not happen. Just in case.
                    return true
                }
                
                for fileURL in sortedFiles {
                    
                    do {
                        try self.fileManager.removeItem(at: fileURL)
                    } catch { }
                    
                    URLsToDelete.append(fileURL)
                    
                    if let fileSize = cachedFiles[fileURL]?.totalFileAllocatedSize {
                        CacheSize -= UInt(fileSize)
                    }
                    
                    if CacheSize < targetSize {
                        break
                    }
                }
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                handler?()
            })
        }
    }
    
    // MARK: Helpers
    // This method is from Kingfisher
    fileprivate func travelCachedFiles(onlyForCacheSize: Bool) -> (urlsToDelete: [URL], CacheSize: UInt, cachedFiles: [URL: URLResourceValues]) {
        
        let CacheURL = URL(fileURLWithPath: cachePath)
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .contentAccessDateKey, .totalFileAllocatedSizeKey]
        let expiredDate: Date? = (cachePeriodInSecond < 0) ? nil : Date(timeIntervalSinceNow: -cachePeriodInSecond)
        
        var cachedFiles = [URL: URLResourceValues]()
        var urlsToDelete = [URL]()
        var CacheSize: UInt = 0
        
        for fileUrl in (try? fileManager.contentsOfDirectory(at: CacheURL, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)) ?? [] {
            
            do {
                let resourceValues = try fileUrl.resourceValues(forKeys: resourceKeys)
                // If it is a Directory. Continue to next file URL.
                if resourceValues.isDirectory == true {
                    continue
                }
                
                // If this file is expired, add it to URLsToDelete
                if !onlyForCacheSize,
                    let expiredDate = expiredDate,
                    let lastAccessData = resourceValues.contentAccessDate,
                    (lastAccessData as NSDate).laterDate(expiredDate) == expiredDate
                {
                    urlsToDelete.append(fileUrl)
                    continue
                }
                
                if let fileSize = resourceValues.totalFileAllocatedSize {
                    CacheSize += UInt(fileSize)
                    if !onlyForCacheSize {
                        cachedFiles[fileUrl] = resourceValues
                    }
                }
            } catch _ { }
        }
        
        return (urlsToDelete, CacheSize, cachedFiles)
    }
    
    func cachePath(forKey key: String) -> String {
        let fileName = key
        return (cachePath as NSString).appendingPathComponent(fileName)
    }
    
}
