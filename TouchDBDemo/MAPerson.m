//
//  MAPerson.m
//  SlickContacts
//
//  Created by Manuel Alabor on 08.05.13.
//  Copyright (c) 2013 Manuel Alabor. All rights reserved.
//

#import "MAPerson.h"

@implementation MAPerson
@dynamic name;
@dynamic photo;

-(void)setPhotoWithImage:(UIImage *)image {
	self.photo = UIImageJPEGRepresentation(image, 0.7);
}

@end
