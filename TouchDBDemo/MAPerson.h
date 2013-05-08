//
//  MAPerson.h
//  SlickContacts
//
//  Created by Manuel Alabor on 08.05.13.
//  Copyright (c) 2013 Manuel Alabor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CouchCocoa/CouchCocoa.h>

@interface MAPerson : CouchModel
@property (copy) NSString *name;
@property (strong) NSData *photo;

-(void)setPhotoWithImage:(UIImage*)image;
@end
