//
//  MAPersonEditorViewController.m
//  TouchDBDemo
//
//  Created by Manuel Alabor on 08.05.13.
//  Copyright (c) 2013 Manuel Alabor. All rights reserved.
//

#import "MAPersonEditorViewController.h"

@interface MAPersonEditorViewController ()

@end

@implementation MAPersonEditorViewController

@synthesize data = _data;

-(void)viewDidLoad {
	if(self.navigationController.viewControllers.count > 1) {
		// Not shown in modal view, so remove the cancel button :)
		self.navigationItem.leftBarButtonItem = nil;
	}
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	self.txtName.text = [self.data objectForKey:@"name"];
}

- (IBAction)onCancel:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onSave:(id)sender {
	if(self.delegate) {
		NSMutableDictionary *data = [NSMutableDictionary dictionaryWithDictionary:self.data];
		[data setValue:self.txtName.text forKey:@"name"];
		
		[self.delegate personEditor:self dismissedWithPerson:data];
	}
	
	if(self.navigationController.viewControllers.count > 1) {
		[self.navigationController popViewControllerAnimated:YES];
	} else {
		// I'm modal, so dismiss me ;)
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}
@end
