//
//  MAPersonEditorViewController.m
//  TouchDBDemo
//
//  Created by Manuel Alabor on 08.05.13.
//  Copyright (c) 2013 Manuel Alabor. All rights reserved.
//

#import "MAPersonEditorViewController.h"
#import "UIImage+Resize.h"
#import <SVProgressHUD.h>

@interface MAPersonEditorViewController () <UIImagePickerControllerDelegate>
@end

@implementation MAPersonEditorViewController

@synthesize person = _person;

-(void)viewDidLoad {
	if(self.navigationController.viewControllers.count > 1) {
		// Not shown in modal view, so remove the cancel button :)
		self.navigationItem.leftBarButtonItem = nil;
	}
	
	self.txtName.text = self.person.name;
	self.imgPhoto.image = [UIImage imageWithData:self.person.photo];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == 1) {
		[self takePhoto];
	}
}

-(void)takePhoto {
	UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
	imagePicker.delegate = self;
	[self presentViewController:imagePicker animated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	UIImage *pickedPhoto = [info objectForKey:UIImagePickerControllerOriginalImage];
	UIImage *smallPhoto = [pickedPhoto thumbnailImage:80 transparentBorder:0 cornerRadius:0 interpolationQuality:0.7];
	self.imgPhoto.image = smallPhoto;
	
	[picker dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onCancel:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onSave:(id)sender {
	if(self.delegate) {
		self.person.name = self.txtName.text;
		[self.person setPhotoWithImage:self.imgPhoto.image];
		
		[self.delegate personEditor:self dismissedWithPerson:self.person];
	}
	
	if(self.navigationController.viewControllers.count > 1) {
		[self.navigationController popViewControllerAnimated:YES];
	} else {
		// I'm modal, so dismiss me ;)
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}

@end
