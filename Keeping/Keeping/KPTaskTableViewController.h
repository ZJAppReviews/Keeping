//
//  KPTaskTableViewController.h
//  Keeping
//
//  Created by 宋 奎熹 on 2017/1/17.
//  Copyright © 2017年 宋 奎熹. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KPTaskTableViewCell.h"
#import "KPWeekdayPickerView.h"
#import "CardsView.h"
#import "KPWeekdayPickerView.h"

@interface KPTaskTableViewController : UITableViewController <PassImgDelegate, KPWeekdayPickerDelegate>

@property (nonnull, nonatomic) IBOutlet CardsView *cView;

@property (nonnull, nonatomic) NSMutableArray *taskArr;
@property (nonnull, nonatomic) NSMutableArray *historyTaskArr;

@property (nonatomic, nonnull) IBOutlet UIStackView *pageStack;

@property (nonatomic, nonnull) IBOutlet UIStackView *colorStack;    //button tag : 1 ~ 7
@property (nonatomic) int selectedColorNum;

@property (nonnull, nonatomic) NSMutableArray *selectedWeekdayArr;

@property (nonnull, nonatomic) IBOutlet KPWeekdayPickerView *weekDayView;

@property (nonnull, nonatomic) NSString *sortFactor;
@property (nonatomic) BOOL isAscend;

- (void)addAction:(_Nonnull id)senders;
- (void)editAction:(_Nonnull id)senders;

@end
