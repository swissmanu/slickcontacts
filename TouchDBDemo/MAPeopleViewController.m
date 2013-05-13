//
//  MAPeopleViewController.m
//  TouchDBDemo
//
//  Created by Manuel Alabor on 08.05.13.
//  Copyright (c) 2013 Manuel Alabor. All rights reserved.
//

#import "MAPeopleViewController.h"
#import <CouchCocoa/CouchCocoa.h>
#import <SVProgressHUD.h>
#import "MAPerson.h"
#import "MAPersonEditorViewController.h"
#import <TestFlight.h>

@interface MAPeopleViewController ()<MAPersonEditorDelegate> {
	CouchDatabase *_db;
	CouchPersistentReplication *_pull;
	CouchPersistentReplication *_push;
	
	CouchLiveQuery *_liveQuery;
	
	NSArray *_tableData;
}

@end

@implementation MAPeopleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	_tableData = @[];
	
    CouchTouchDBServer* server = [CouchTouchDBServer sharedInstance];
	
    if (server.error) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error :(", nil)
														message:[NSString stringWithFormat:@"%@", server.error]
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"Close", nil)
											  otherButtonTitles: nil];
		[alert show];
	}
	
    _db = [server databaseNamed: @"mydb"];  // db name must be lowercase!
	
    NSError* error;
    if (![_db ensureCreated: &error]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error :(", nil)
														message:[NSString stringWithFormat:@"%@", error]
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"Close", nil)
											  otherButtonTitles: nil];
		[alert show];
    }
	
	NSArray *replications = [_db replicateWithURL:[NSURL URLWithString:COUCHDB_URL]
									  exclusively:YES];
	_pull = [replications objectAtIndex:0];
	_push = [replications objectAtIndex:1];
	[_pull addObserver:self forKeyPath:@"completed" options:0 context:nil];
	[_push addObserver:self forKeyPath:@"completed" options:0 context:nil];
	
	CouchDesignDocument *designDocument = [_db designDocumentWithName:@"contacts"];
	[designDocument defineViewNamed:@"byName" mapBlock:^(NSDictionary *doc, TDMapEmitBlock emit) {
		id name = [doc objectForKey:@"name"];
		if(name) {
			emit(name, doc);
		}
	} version:@"1.0"];
	
	_liveQuery = [[designDocument queryViewNamed:@"byName"] asLiveQuery];
	[_liveQuery addObserver:self forKeyPath:@"rows" options:0 context:nil];
	
	[self reloadData];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
    if (object == _pull || object == _push) {
        unsigned completed = _pull.completed + _push.completed;
        unsigned total = _pull.total + _push.total;
        if (total > 0 && completed < total) {
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
			[TestFlight passCheckpoint:@"Started replication"];
        } else {
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
			[TestFlight passCheckpoint:@"Finished replication"];
			[self reloadData];
        }
    } else if(object == _liveQuery) {
		[self reloadData];
	}
}

-(void)reloadData {
	NSMutableArray *people = [NSMutableArray arrayWithCapacity:10];
	for(CouchQueryRow *row in _liveQuery.rows) {
		if(!row.document.isDeleted) {
			MAPerson *person = [MAPerson modelForDocument:row.document];
			[people addObject:person];
		}
	}
	
	_tableData = [NSArray arrayWithArray:people];
	[self.tableView reloadData];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NSInteger count = 0;
	if(_tableData.count > 0) { count = 1; }
	
	return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	
	return [self configureCell:cell atIndexPath:indexPath];
}

-(UITableViewCell*)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath {
	UILabel *lblTitle = (UILabel*)[cell viewWithTag:1];
	UIImageView *imgPhoto = (UIImageView*)[cell viewWithTag:2];
	
	MAPerson *person = [_tableData objectAtIndex:indexPath.row];
	NSData *imageData = person.photo;
	
	lblTitle.text = person.name;
	
	if(imageData) {
		UIImage *photo = [UIImage imageWithData:imageData];
		if(photo) {
			imgPhoto.image = photo;
		} else {
			imgPhoto.image = [UIImage imageNamed:@"mrunknown.jpg"];
		}
	} else {
		imgPhoto.image = [UIImage imageNamed:@"mrunknown.jpg"];
	}
    
    return cell;
}

-(MAPerson*)selectedPerson {
	NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
	MAPerson *person = [_tableData objectAtIndex:indexPath.row];
	
	return person;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	MAPerson *person = [_tableData objectAtIndex:indexPath.row];
	RESTOperation *op = [person deleteDocument];
	
	[op onCompletion:^{
		[SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Deleted", nil)];
		[TestFlight passCheckpoint:@"Contact deleted."];
	}];
	[SVProgressHUD showWithStatus:NSLocalizedString(@"Deleting...", nil)];
	[TestFlight passCheckpoint:@"Delete contact..."];
	[op start];
}


#pragma mark - PersonEditor Delegate

-(void)personEditor:(MAPersonEditorViewController *)personEditor dismissedWithPerson:(MAPerson*)person {
	if(person.name.length > 0) {
		RESTOperation *op = [person save];
		
		[op onCompletion:^{
			[SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Saved", nil)];
			[TestFlight passCheckpoint:@"Contact saved."];
		}];
		[SVProgressHUD showWithStatus:NSLocalizedString(@"Saving...", nil)];
		[TestFlight passCheckpoint:@"Saving contanct..."];
		[op start];
	}
}


#pragma mark - Segue Preparation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	NSString *segueIdentifier = segue.identifier;
	
	if([segueIdentifier isEqualToString:@"Add"]) {
		UINavigationController *navigationController = (UINavigationController*)segue.destinationViewController;
		MAPersonEditorViewController *editor = (MAPersonEditorViewController*)[navigationController.viewControllers objectAtIndex:0];
		editor.person = [[MAPerson alloc] initWithNewDocumentInDatabase:_db];
		editor.delegate = self;
	} else if([segueIdentifier isEqualToString:@"Edit"]) {
		MAPersonEditorViewController *editor = (MAPersonEditorViewController*)segue.destinationViewController;
		MAPerson *person = [self selectedPerson];
		editor.person = person;
		editor.delegate = self;
	}
}

@end
