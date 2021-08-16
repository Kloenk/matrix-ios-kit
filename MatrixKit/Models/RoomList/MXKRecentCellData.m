/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MXKRecentCellData.h"

#import "MXKSessionRecentsDataSource.h"
#import "MXEvent+MatrixKit.h"
#import <MatrixSDK/MatrixSDK-Swift.h>

@implementation MXKRecentCellData
@synthesize roomSummary, spaceChildInfo, recentsDataSource, roomDisplayname, lastEventTextMessage, lastEventAttributedTextMessage, lastEventDate;

- (instancetype)initWithRoomSummary:(MXRoomSummary*)theRoomSummary andRecentListDataSource:(MXKSessionRecentsDataSource*)recentListDataSource
{
    self = [self init];
    if (self)
    {
        roomSummary = theRoomSummary;
        recentsDataSource = recentListDataSource;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:kMXRoomSummaryDidChangeNotification object:roomSummary];

        [self update];
    }
    return self;
}

- (instancetype)initWithSpaceChildInfo:(MXSpaceChildInfo*)theSpaceChildInfo andRecentListDataSource:(MXKSessionRecentsDataSource*)recentListDataSource
{
    self = [self init];
    if (self)
    {
        spaceChildInfo = theSpaceChildInfo;
        recentsDataSource = recentListDataSource;

        [self update];
    }
    return self;
}

- (void)update
{
    // Keep ref on displayed last event
    roomDisplayname = spaceChildInfo ? spaceChildInfo.name : roomSummary.displayname;

    lastEventTextMessage = spaceChildInfo ? spaceChildInfo.topic : roomSummary.lastMessage.text;
    lastEventAttributedTextMessage = spaceChildInfo ? nil : roomSummary.lastMessage.attributedText;
}

- (void)dealloc
{
    if (roomSummary)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXRoomSummaryDidChangeNotification object:roomSummary];
    }
    roomSummary = nil;
    spaceChildInfo = nil;

    lastEventTextMessage = nil;
    lastEventAttributedTextMessage = nil;
}

- (NSString*)lastEventDate
{
    return (NSString*)roomSummary.lastMessage.others[@"lastEventDate"];
}

- (BOOL)hasUnread
{
    return (roomSummary.localUnreadEventCount != 0);
}

- (NSUInteger)notificationCount
{
    return roomSummary.notificationCount;
}

- (NSUInteger)highlightCount
{
    return roomSummary.highlightCount;
}

- (NSString*)notificationCountStringValue
{
    return [NSString stringWithFormat:@"%tu", self.notificationCount];
}

- (void)markAllAsRead
{
    [roomSummary markAllAsRead];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ %@: %@ - %@", super.description, self.roomSummary.roomId, self.roomDisplayname, self.lastEventTextMessage];
}

- (BOOL)isSuggestedRoom
{
    // As off now, we only store MXSpaceChildInfo in case of suggested rooms
    return self.spaceChildInfo != nil;
}

@end
