//
//  KPTodayTableViewController.m
//  Keeping
//
//  Created by 宋 奎熹 on 2017/1/17.
//  Copyright © 2017年 宋 奎熹. All rights reserved.
//

#import "KPTodayTableViewController.h"
#import "KPSeparatorView.h"
#import "KPTodayTableViewCell.h"
#import "Utilities.h"
#import "TaskManager.h"
#import "Task.h"
#import "DateUtil.h"
#import "DateTools.h"
#import "UIScrollView+EmptyDataSet.h"
#import "KPImageViewController.h"
#import "MLKMenuPopover.h"
#import "AMPopTip.h"
#import "CardsView.h"
#import "TaskDataHelper.h"

#define MENU_POPOVER_FRAME CGRectMake(10, 44 + 9, 140, 44 * [[Utilities getTaskSortArr] count])

static AMPopTip *shareTip = NULL;

@interface KPTodayTableViewController () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MLKMenuPopoverDelegate>

@property (nonatomic, strong) MLKMenuPopover *_Nonnull menuPopover;

@property (nonatomic, strong) AMPopTip *tip;
@property (nonatomic, strong) AMPopTip *calTip;

@end

@implementation KPTodayTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    self.sortFactor = @"sortName";
    self.isAscend = true;
    self.selectedDate = [NSDate dateWithYear:[[NSDate date] year] month:[[NSDate date] month] day:[[NSDate date] day]];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    //类别按钮
    self.colorView.colorDelegate = self;
    
    //page 指示 stack
    self.dateStack.hidden = NO;
    self.colorView.hidden = YES;
    for(UIImageView *imgView in self.pageStack.subviews){
        UIImage *img = [UIImage imageNamed:@"CIRCLE_FULL"];
        img = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [imgView setImage:img];
    }
    [self.pageStack.subviews[0] setTintColor:[Utilities getColor]];
    [self.pageStack.subviews[1] setTintColor:[UIColor groupTableViewBackgroundColor]];
    
    UISwipeGestureRecognizer *swipeGRLeft1 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
    UISwipeGestureRecognizer *swipeGRRight1 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
    swipeGRLeft1.direction = UISwipeGestureRecognizerDirectionLeft;
    swipeGRRight1.direction = UISwipeGestureRecognizerDirectionRight;
    UISwipeGestureRecognizer *swipeGRLeft2 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
    UISwipeGestureRecognizer *swipeGRRight2 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
    swipeGRLeft2.direction = UISwipeGestureRecognizerDirectionLeft;
    swipeGRRight2.direction = UISwipeGestureRecognizerDirectionRight;
    
    [self.colorView addGestureRecognizer:swipeGRLeft1];
    [self.colorView addGestureRecognizer:swipeGRRight1];
    [self.dateStack addGestureRecognizer:swipeGRLeft2];
    [self.dateStack addGestureRecognizer:swipeGRRight2];
}

- (void)viewWillAppear:(BOOL)animated{
    [self.progressLabel setFont:[UIFont fontWithName:[Utilities getFont] size:40.0f]];
    [self.dateButton.titleLabel setFont:[UIFont fontWithName:[Utilities getFont] size:15.0f]];
    [self.dateButton setTitleColor:[Utilities getColor] forState:UIControlStateNormal];
    
    [self loadTasks];
}

- (void)viewWillDisappear:(BOOL)animated{
    self.selectedIndexPath = NULL;
    if([[KPTodayTableViewController shareTipInstance] isAnimating]
       || [[KPTodayTableViewController shareTipInstance] isVisible]){
        [[KPTodayTableViewController shareTipInstance] hide];
        shareTip = NULL;
    }
}

- (void)loadTasks{
    if([self.tip isVisible] || [self.tip isAnimating]){
        [self.tip hide];
    }
    
    [self.dateButton setTitle:[DateUtil getDateStringOfDate:self.selectedDate] forState:UIControlStateNormal];
    self.selectedIndexPath = NULL;
    
    self.unfinishedTaskArr = [[NSMutableArray alloc] init];
    self.finishedTaskArr = [[NSMutableArray alloc] init];
    
    NSMutableArray *taskArr = [[TaskManager shareInstance] getTasksOfDate:self.selectedDate];
    for (Task *task in taskArr) {
        if([task.punchDateArr containsObject:[DateUtil transformDate:self.selectedDate]]){
            [self.finishedTaskArr addObject:task];
        }else{
            [self.unfinishedTaskArr addObject:task];
        }
    }
    
    //排序
    self.unfinishedTaskArr = [NSMutableArray arrayWithArray:[TaskDataHelper sortTasks:self.unfinishedTaskArr withSortFactor:self.sortFactor isAscend:self.isAscend]];
    self.finishedTaskArr = [NSMutableArray arrayWithArray:[TaskDataHelper sortTasks:self.finishedTaskArr withSortFactor:self.sortFactor isAscend:self.isAscend]];
    
    //按类别
    self.unfinishedTaskArr = [NSMutableArray arrayWithArray:[TaskDataHelper filtrateTasks:self.unfinishedTaskArr withType:self.selectedColorNum]];
    self.finishedTaskArr = [NSMutableArray arrayWithArray:[TaskDataHelper filtrateTasks:self.finishedTaskArr withType:self.selectedColorNum]];
    
    [self.progressLabel setText:[NSString stringWithFormat:@"%lu / %lu", (unsigned long)self.finishedTaskArr.count, ((unsigned long)self.finishedTaskArr.count + (unsigned long)self.unfinishedTaskArr.count)]];
    
    [self.tableView reloadData];
    
    [self.tableView reloadEmptyDataSet];
    
    [self fadeAnimation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)swipeAction:(UISwipeGestureRecognizer *)sender{
    
    if([self.colorView isHidden]){
        [self.colorView setHidden:NO];
        [self.dateStack setHidden:YES];
        
        [self.pageStack.subviews[0] setTintColor:[UIColor groupTableViewBackgroundColor]];
        [self.pageStack.subviews[1] setTintColor:[Utilities getColor]];
    }else{
        [self.colorView setHidden:YES];
        [self.dateStack setHidden:NO];
        
        [self.pageStack.subviews[0] setTintColor:[Utilities getColor]];
        [self.pageStack.subviews[1] setTintColor:[UIColor groupTableViewBackgroundColor]];
    }
    
    [self fadeAnimation];
}

- (void)addAction:(id)senders{
    [self performSegueWithIdentifier:@"addTaskSegue" sender:nil];
}

- (void)editAction:(id)sender{
    [self.menuPopover dismissMenuPopover];
    
    self.menuPopover = [[MLKMenuPopover alloc] initWithFrame:MENU_POPOVER_FRAME menuItems:[[Utilities getTaskSortArr] allKeys]];
    self.menuPopover.menuPopoverDelegate = self;
    [self.menuPopover showInView:self.navigationController.view];
}

#pragma mark - Choose Date

- (IBAction)chooseDateAction:(id)sender{
    
    AMPopTip *tp = [KPTodayTableViewController shareTipInstance];
    
    if(![tp isVisible] && ![tp isAnimating]){
        
        self.calendar = [[FSCalendar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 20, 250)];
        self.calendar.dataSource = self;
        self.calendar.delegate = self;
        self.calendar.backgroundColor = [UIColor whiteColor];
        self.calendar.layer.cornerRadius = 10;
        
        self.calendar.appearance.titleFont = [UIFont fontWithName:[Utilities getFont] size:12.0];
        self.calendar.appearance.headerTitleFont = [UIFont fontWithName:[Utilities getFont] size:15.0];
        self.calendar.appearance.weekdayFont = [UIFont fontWithName:[Utilities getFont] size:15.0];
        self.calendar.appearance.subtitleFont = [UIFont fontWithName:[Utilities getFont] size:10.0];
        
        self.calendar.appearance.headerMinimumDissolvedAlpha = 0;
        self.calendar.appearance.headerDateFormat = @"yyyy 年 MM 月";
        
        self.calendar.appearance.headerTitleColor = [Utilities getColor];
        self.calendar.appearance.weekdayTextColor = [Utilities getColor];
        
//        self.calendar.appearance.todayColor = [UIColor whiteColor];
//        self.calendar.appearance.titleTodayColor = [UIColor whiteColor];
        self.calendar.appearance.selectionColor =  [Utilities getColor];
        self.calendar.appearance.titleSelectionColor = [UIColor whiteColor];
//        self.calendar.appearance.todaySelectionColor = [Utilities getColor];
        
        UIButton *previousButton = [UIButton buttonWithType:UIButtonTypeCustom];
        previousButton.frame = CGRectMake(5, 5, 95, 34);
        previousButton.backgroundColor = [UIColor whiteColor];
        previousButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [previousButton setTintColor:[Utilities getColor]];
        UIImage *leftImg = [UIImage imageNamed:@"icon_prev"];
        leftImg = [leftImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [previousButton setImage:leftImg forState:UIControlStateNormal];
        [previousButton addTarget:self action:@selector(previousClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.calendar addSubview:previousButton];
        self.previousButton = previousButton;
        
        UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        nextButton.frame = CGRectMake(CGRectGetWidth(self.calendar.frame)-100, 5, 95, 34);
        nextButton.backgroundColor = [UIColor whiteColor];
        nextButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [nextButton setTintColor:[Utilities getColor]];
        UIImage *rightImg = [UIImage imageNamed:@"icon_next"];
        rightImg = [rightImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [nextButton setImage:rightImg forState:UIControlStateNormal];
        [nextButton addTarget:self action:@selector(nextClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.calendar addSubview:nextButton];
        self.nextButton = nextButton;
        
        [self.calendar selectDate:self.selectedDate scrollToDate:YES];
        
        [tp showCustomView:self.calendar
                          direction:AMPopTipDirectionNone
                             inView:self.tableView
                          fromFrame:self.tableView.frame];
        
        tp.textColor = [UIColor whiteColor];
        tp.tintColor = [Utilities getColor];
        tp.popoverColor = [Utilities getColor];
        tp.borderColor = [UIColor whiteColor];
        
        tp.radius = 15;
    }
}

- (void)previousClicked:(id)sender{
    NSDate *currentMonth = self.calendar.currentPage;
    NSDate *previousMonth = [self.gregorian dateByAddingUnit:NSCalendarUnitMonth value:-1 toDate:currentMonth options:0];
    [self.calendar setCurrentPage:previousMonth animated:YES];
}

- (void)nextClicked:(id)sender{
    NSDate *currentMonth = self.calendar.currentPage;
    NSDate *nextMonth = [self.gregorian dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:currentMonth options:0];
    [self.calendar setCurrentPage:nextMonth animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
        case 1:
            return [self.unfinishedTaskArr count];
        case 2:
            return [self.finishedTaskArr count];
        default:
            return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 1:
        {
            if([self.unfinishedTaskArr count] == 0){
                return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
            }else{
                KPSeparatorView *view = [[[NSBundle mainBundle] loadNibNamed:@"KPSeparatorView" owner:nil options:nil] lastObject];
                view.backgroundColor = [UIColor clearColor];
                [view setText:@"未完成"];
                return view;
            }
        }
        case 2:
        {
            if([self.finishedTaskArr count] == 0){
                return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
            }else{
                KPSeparatorView *view = [[[NSBundle mainBundle] loadNibNamed:@"KPSeparatorView" owner:nil options:nil] lastObject];
                view.backgroundColor = [UIColor clearColor];
                [view setText:@"已完成"];
                return view;
            }
        }
        default:
            return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    switch (section) {
        case 1:
        {
            if([self.unfinishedTaskArr count] == 0){
                return 0.00001f;
            }else{
                return 20.0f;
            }
        }
        case 2:
            return 20.0f;
        default:
            return 0.00001f;
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 100)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.00001f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 1:
        case 2:
        {
            static NSString *cellIdentifier = @"KPTodayTableViewCell";
            UINib *nib = [UINib nibWithNibName:@"KPTodayTableViewCell" bundle:nil];
            [tableView registerNib:nib forCellReuseIdentifier:cellIdentifier];
            KPTodayTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
            
            [cell setFont];
            
            cell.delegate = self;
            
            Task *t;
            if(indexPath.section == 1){
                t = self.unfinishedTaskArr[indexPath.row];
                
                [cell setIsFinished:NO];
            }else{
                t = self.finishedTaskArr[indexPath.row];
                
                [cell setIsFinished:YES];
            }
            [cell.taskNameLabel setText:t.name];
            
            if(t.type > 0){
                UIImage *img = [UIImage imageNamed:@"CIRCLE_FULL"];
                img = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.typeImg.tintColor = [Utilities getTypeColorArr][t.type - 1];
                [cell.typeImg setImage:img];
            }else{
                [cell.typeImg setImage:[UIImage new]];
            }
            
            [cell.moreButton setHidden:YES];
            
            if(t.appScheme != NULL){
                [cell.moreButton setHidden:NO];
                
                NSDictionary *d = t.appScheme;
                NSString *s = d.allKeys[0];
                [cell.appButton setTitle:[NSString stringWithFormat:@"%@", s] forState:UIControlStateNormal];
                [cell.appButton setTitleColor:[Utilities getColor] forState:UIControlStateNormal];
                [cell.appButton setUserInteractionEnabled:YES];
                
                UIImage *appImg = [UIImage imageNamed:@"TODAY_APP"];
                appImg = [appImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                [cell.appImg setImage:appImg];
                [cell.appButton setHidden:NO];
                [cell.appImg setHidden:NO];
            }else{
                [cell.appButton setHidden:YES];
                [cell.appImg setHidden:YES];
            }
            
            if(t.link != NULL && ![t.link isEqualToString:@""]){
                [cell.moreButton setHidden:NO];
                
                [cell.linkButton setTitle:@"链接" forState:UIControlStateNormal];
                [cell.linkButton setTitleColor:[Utilities getColor] forState:UIControlStateNormal];
                [cell.linkButton setUserInteractionEnabled:YES];
                
                UIImage *linkImg = [UIImage imageNamed:@"TODAY_LINK"];
                linkImg = [linkImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                [cell.linkImg setImage:linkImg];
                [cell.linkButton setHidden:NO];
                [cell.linkImg setHidden:NO];
            }else{
                [cell.linkButton setHidden:YES];
                [cell.linkImg setHidden:YES];
            }
            
            if(t.image != NULL){
                [cell.moreButton setHidden:NO];
                
                [cell.imageButton setTitle:@"图片" forState:UIControlStateNormal];
                [cell.imageButton setTitleColor:[Utilities getColor] forState:UIControlStateNormal];
                [cell.imageButton setUserInteractionEnabled:YES];
                
                UIImage *imageImg = [UIImage imageNamed:@"TODAY_IMAGE"];
                imageImg = [imageImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                [cell.imageImg setImage:imageImg];
                [cell.imageButton setHidden:NO];
                [cell.imageImg setHidden:NO];
            }else{
                [cell.imageButton setHidden:YES];
                [cell.imageImg setHidden:YES];
            }
            
            if(t.memo != NULL && ![t.memo isEqualToString:@""]){
                [cell.moreButton setHidden:NO];
                
                [cell.memoButton setTitle:@"备注" forState:UIControlStateNormal];
                [cell.memoButton setTitleColor:[Utilities getColor] forState:UIControlStateNormal];
                [cell.memoButton setUserInteractionEnabled:YES];
                
                UIImage *imageImg = [UIImage imageNamed:@"TODAY_TEXT"];
                imageImg = [imageImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                [cell.memoImg setImage:imageImg];
                [cell.memoButton setHidden:NO];
                [cell.memoImg setHidden:NO];
            }else{
                [cell.memoButton setHidden:YES];
                [cell.memoImg setHidden:YES];
            }
            
            NSString *reminderTimeStr = @"";
            if(t.reminderTime != NULL){
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"HH:mm"];
                reminderTimeStr = [dateFormatter stringFromDate:t.reminderTime];
                
                [cell.reminderLabel setText:reminderTimeStr];
                
                [cell.reminderLabel setHidden:NO];
            }else{
                [cell.reminderLabel setHidden:YES];
            }
            
            if(indexPath == self.selectedIndexPath){
                [cell.cardView2 setHidden:NO];
                
                [cell.moreButton setBackgroundImage:[UIImage imageNamed:@"MORE_INFO_UP"] forState:UIControlStateNormal];
            }else{
                [cell.cardView2 setHidden:YES];
                
                [cell.moreButton setBackgroundImage:[UIImage imageNamed:@"MORE_INFO_DOWN"] forState:UIControlStateNormal];
            }
            
            //晚于：不能打卡
            NSDate *tempDate = [NSDate dateWithYear:[[NSDate date] year]
                                              month:[[NSDate date] month]
                                                day:[[NSDate date] day]];
            if(![self.selectedDate isEarlierThanOrEqualTo:tempDate]){
                cell.myCheckBox.userInteractionEnabled = NO;
            }else{
                cell.myCheckBox.userInteractionEnabled = YES;
            }
            
            return cell;
        }
        default:
            return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0){
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }else{
        if(indexPath == self.selectedIndexPath){
            return 120;
        }else{
            return 70;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section != 0) {
        return 10;
    }else{
        return [super tableView:tableView indentationLevelForRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(indexPath.section != 0){
        KPTodayTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if([cell.moreButton isHidden]){
            
        }else{
            if(self.selectedIndexPath == indexPath){
                self.selectedIndexPath = NULL;
            }else{
                self.selectedIndexPath = indexPath;
            }
        }
        
        [tableView reloadData];
        
    }
}

#pragma mark - Check Delegate

- (void)checkTask:(UITableViewCell *)cell{
    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    //section = 1 : 未完成
    if(path.section == 1){
        Task *task = self.unfinishedTaskArr[path.row];
        [[TaskManager shareInstance] punchForTaskWithID:@(task.id) onDate:self.selectedDate];
        [self loadTasks];
    }else if(path.section == 2){
        Task *task = self.finishedTaskArr[path.row];
        [[TaskManager shareInstance] unpunchForTaskWithID:@(task.id) onDate:self.selectedDate];
        [self loadTasks];
    }
}

- (void)moreAction:(UITableViewCell *)cell withButton:(UIButton *)button;{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    Task *t;
    if(indexPath.section == 1){
        t = self.unfinishedTaskArr[indexPath.row];
    }else if(indexPath.section == 2){
        t = self.finishedTaskArr[indexPath.row];
    }
    
    //tag:
    //      = 0 : app
    //      = 1 : 链接
    //      = 2 : 图片
    //      = 3 : 备注
    switch (button.tag) {
        case 0:
        {
            NSString *s = t.appScheme.allValues[0];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:s] options:@{} completionHandler:nil];
        }
            break;
        case 1:
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:t.link] options:@{} completionHandler:nil];
        }
            break;
        case 2:
        {
            [self performSegueWithIdentifier:@"imageSegue" sender:[UIImage imageWithData:t.image]];
        }
            break;
        case 3:
        {
            AMPopTip *tp = [KPTodayTableViewController shareTipInstance];
            if(![tp isVisible] && ![tp isAnimating]){
                [tp showText:t.memo
                         direction:AMPopTipDirectionNone
                          maxWidth:self.view.frame.size.width - 50
                            inView:self.view
                         fromFrame:self.view.frame];
                tp.shouldDismissOnTap = YES;
                
                tp.textColor = [UIColor whiteColor];
                tp.tintColor = [Utilities getColor];
                tp.popoverColor = [Utilities getColor];
                tp.borderColor = [UIColor whiteColor];

                tp.radius = 10;
            }
        }
            break;
        default:
            break;
    }

}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"imageSegue"]){
        KPImageViewController *imageVC = (KPImageViewController *)[segue destinationViewController];
        [imageVC setImg:(UIImage *)sender];
    }
}

#pragma mark - DZNEmptyTableViewDelegate

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView{
    NSString *text = @"没有任务";
    
    NSDictionary *attributes = @{
                                 NSForegroundColorAttributeName: [Utilities getColor],
                                 NSFontAttributeName:[UIFont fontWithName:[Utilities getFont] size:20.0]
                                 };
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (BOOL)emptyDataSetShouldBeForcedToDisplay:(UIScrollView *)scrollView{
    if(self.finishedTaskArr.count + self.unfinishedTaskArr.count == 0){
        return YES;
    }else{
        return NO;
    }
}

#pragma mark - FSCalendarDelegate

- (void)calendar:(FSCalendar *)calendar didSelectDate:(NSDate *)date{
    NSDate *tempDate = [NSDate dateWithYear:[date year] month:[date month] day:[date day]];
    self.selectedDate = tempDate;
    [self.calTip hide];
    [self loadTasks];
}

#pragma mark - MLKMenuPopoverDelegate

- (void)menuPopover:(MLKMenuPopover *)menuPopover didSelectMenuItemAtIndex:(NSInteger)selectedIndex{
    if([self.sortFactor isEqualToString:[[Utilities getTaskSortArr] allValues][selectedIndex]]){
        self.isAscend = !self.isAscend;
    }else{
        self.sortFactor = [[Utilities getTaskSortArr] allValues][selectedIndex];
        self.isAscend = true;
    }
    NSLog(@"按%@排序", self.sortFactor);
    [self loadTasks];
}

#pragma mark - Fade Animation

- (void)fadeAnimation{
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"animation"]){
        CATransition *animation = [CATransition animation];
        animation.duration = 0.3f;
        animation.timingFunction = UIViewAnimationCurveEaseInOut;
        animation.type = [Utilities getAnimationType];
        [self.tableView.layer addAnimation:animation forKey:@"fadeAnimation"];
    }
}

#pragma mark - KPColorPickerDelegate

- (void)didChangeColors:(int)selectColorNum{
    self.selectedColorNum = selectColorNum;
    [self loadTasks];
}

#pragma mark - AMPopTip Singleton

+ (AMPopTip *)shareTipInstance{
    return shareTip == NULL ? shareTip = [AMPopTip popTip] : shareTip;
}

@end
