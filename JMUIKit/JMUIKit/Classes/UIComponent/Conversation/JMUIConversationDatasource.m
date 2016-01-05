//
//  JMUIConversationDatasource.m
//  JMUIKit
//
//  Created by oshumini on 16/1/5.
//  Copyright © 2016年 HXHG. All rights reserved.
//

#import "JMUIConversationDatasource.h"

@interface JMUIConversationDatasource (){
  NSInteger messageOffset;//当前获取消息的指针
  BOOL isNoMoreHistoryMsg;
}

@end

@implementation JMUIConversationDatasource
- (instancetype)initWithConversation:(JMSGConversation*)conversation
                    showTimeInterval:(NSTimeInterval)timeInterval
                  fristPageMsgNumber:(NSInteger)pageNumber
                               limit:(NSInteger)limit {
  if (self = [self init]) {
    _conversation    = conversation;
    _messageLimit      = limit;
    _showTimeInterval  = timeInterval;
    _messagefristPageNumber = pageNumber;
    isNoMoreHistoryMsg = NO;
    _allMessageDic = @{}.mutableCopy;
    _allMessageIdArr = @[].mutableCopy;
  }
  return self;
}

- (void)getPageMessage {
  NSLog(@"Action - getAllMessage");
  
  [_allMessageDic removeAllObjects];
  [_allMessageIdArr removeAllObjects];
  NSMutableArray * arrList = [[NSMutableArray alloc] init];
  [_allMessageIdArr addObject:[[NSObject alloc] init]];
  
  messageOffset = _messagefristPageNumber;
  [arrList addObjectsFromArray:[[[_conversation messageArrayFromNewestWithOffset:@0 limit:@(messageOffset)] reverseObjectEnumerator] allObjects]];
  if ([arrList count] < _messagefristPageNumber) {
    isNoMoreHistoryMsg = YES;
    [_allMessageIdArr removeObjectAtIndex:0];
  }
  
  for (NSInteger i=0; i< [arrList count]; i++) {
    JMSGMessage *message = [arrList objectAtIndex:i];
    JMUIChatModel *model = [[JMUIChatModel alloc] init];
    [model setChatModelWith:message conversationType:_conversation];
    if (message.contentType == kJMSGContentTypeImage) {
    }
    
    [self dataMessageShowTime:message.timestamp];
    [_allMessageDic setObject:model forKey:model.message.msgId];
    [_allMessageIdArr addObject:model.message.msgId];
  }
//  [_messageListTable reloadData];
//  [self scrollToBottomAnimated:NO];
}

- (void)addMessage:(JMUIChatModel *)model {
  if (model.isTime) {
    [_allMessageDic setObject:model forKey:model.timeId];
    [_allMessageIdArr addObject:model.timeId];
  } else {
    [_allMessageDic setObject:model forKey:model.message.msgId];
    [_allMessageIdArr addObject:model.message.msgId];
  }
//  [self addCellToTabel];
}

//比较和上一条消息时间超过5分钟之内增加时间model
- (void)dataMessageShowTime:(NSNumber *)timeNumber{
  NSString *messageId = [_allMessageIdArr lastObject];
  JMUIChatModel *lastModel = _allMessageDic[messageId];
  NSTimeInterval timeInterVal = [timeNumber longLongValue];
  
  if ([_allMessageIdArr count]>0 && lastModel.isTime == NO) {
    NSDate* lastdate = [NSDate dateWithTimeIntervalSince1970:[lastModel.messageTime doubleValue]];
    NSDate* currentDate = [NSDate dateWithTimeIntervalSince1970:timeInterVal];
    NSTimeInterval timeBetween = [currentDate timeIntervalSinceDate:lastdate];
    if (fabs(timeBetween) > _showTimeInterval) {
      JMUIChatModel *timeModel =[[JMUIChatModel alloc] init];
      timeModel.timeId = [self getTimeId];
      timeModel.isTime = YES;
      timeModel.messageTime = @(timeInterVal);
      timeModel.contentHeight = [timeModel getTextHeight];//!
      [_allMessageDic setObject:timeModel forKey:timeModel.timeId];
      [_allMessageIdArr addObject:timeModel.timeId];
    }
  } else if ([_allMessageIdArr count] ==0) {//首条消息显示时间
    JMUIChatModel *timeModel =[[JMUIChatModel alloc] init];
    timeModel.timeId = [self getTimeId];
    timeModel.isTime = YES;
    timeModel.messageTime = @(timeInterVal);
    timeModel.contentHeight = [timeModel getTextHeight];//!
    [_allMessageDic setObject:timeModel forKey:timeModel.timeId];
    [_allMessageIdArr addObject:timeModel.timeId];
  } else {
    NSLog(@"不用显示时间");
  }
}

- (NSString *)getTimeId {
  NSString *timeId = [NSString stringWithFormat:@"%d",arc4random()%1000000];
  return timeId;
}
@end
