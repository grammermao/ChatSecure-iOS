//
//  YapDatabse+ChatSecure.swift
//  ChatSecure
//
//  Created by David Chiles on 10/20/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase

@objc public enum DatabaseViewNames: Int {
    case UnsentGroupMessagesViewName
    
    public func name() -> String {
        switch self {
        case UnsentGroupMessagesViewName: return "UnsentGroupMessagesViewName"
        }
    }
}

public extension YapDatabase {
    
    func asyncRegisterView(grouping:YapDatabaseViewGrouping, sorting:YapDatabaseViewSorting, version:String, whiteList:Set<String>, name:DatabaseViewNames, completionQueue:dispatch_queue_t?, completionBlock:((Bool) ->Void)?) {
        
        if (self.registeredExtension(name.name()) != nil ) {
            let queue:dispatch_queue_t = completionQueue ?? dispatch_get_main_queue()
            if let block = completionBlock {
                dispatch_async(queue, { () -> Void in
                    block(true)
                })
            }
            return
        }
        
        let options = YapDatabaseViewOptions()
        options.allowedCollections = YapWhitelistBlacklist(whitelist: whiteList)
        let view = YapDatabaseView(grouping: grouping, sorting: sorting, versionTag: version, options: options)
        self.asyncRegisterExtension(view, withName: name.name(), completionQueue: completionQueue, completionBlock: completionBlock)
    }
    
    public func asyncRegisterUnsentGroupMessagesView(completionQueue:dispatch_queue_t?, completionBlock:((Bool) ->Void)?) {
        
        self.asyncRegisterView(YapDatabaseViewGrouping.withObjectBlock({ (collection, key, object) -> String! in
            guard let message = object as? OTRXMPPRoomMessage else {
                return nil
            }
            
            guard let roomId = message.roomUniqueId where message.state == .NeedsSending else {
                return nil
            }
            
            return roomId
            
        }), sorting: YapDatabaseViewSorting.withObjectBlock({ (group, collection1, key1, object1, collection2, key2, object2) -> NSComparisonResult in
            
            guard let date1 = (object1 as? OTRXMPPRoomMessage)?.messageDate else {
                return .OrderedSame
            }
            
            guard let date2 = (object2 as? OTRXMPPRoomMessage)?.messageDate else  {
                return .OrderedSame
            }
            
            return date1.compare(date2)
        }), version: "1", whiteList: [OTRXMPPRoomMessage.collection()], name: .UnsentGroupMessagesViewName, completionQueue:completionQueue, completionBlock:completionBlock)
    }
    
    //Needed for Obj-C
    public class func viewName(name:DatabaseViewNames) -> String {
        return name.name()
    }
}