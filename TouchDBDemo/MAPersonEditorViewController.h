//
//  MAPersonEditorViewController.h
//  TouchDBDemo
//
//  Created by Manuel Alabor on 08.05.13.
//  Copyright (c) 2013 Manuel Alabor. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MAPersonEditorViewController;

@protocol MAPersonEditorDelegate
-(void)personEditor:(MAPersonEditorViewController*)personEditor dismissedWithPerson:(NSDictionary*)person;
@end

@interface MAPersonEditorViewController : UITableViewController
@property (strong) id<MAPersonEditorDelegate> delegate;
@property (strong, nonatomic) IBOutlet UITextField *txtName;

@property (strong) NSDictionary *data;

- (IBAction)onCancel:(id)sender;
- (IBAction)onSave:(id)sender;
@end
