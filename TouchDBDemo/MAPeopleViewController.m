//
//  MAPeopleViewController.m
//  TouchDBDemo
//
//  Created by Manuel Alabor on 08.05.13.
//  Copyright (c) 2013 Manuel Alabor. All rights reserved.
//

#import "MAPeopleViewController.h"
#import <CouchCocoa/CouchCocoa.h>
#import "MAPersonEditorViewController.h"

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
	
	NSArray *replications = [_db replicateWithURL:[NSURL URLWithString:@"http://alabor.me:5984/persons"]
									  exclusively:YES];
	_pull = [replications objectAtIndex:0];
	_push = [replications objectAtIndex:1];
	[_pull addObserver:self forKeyPath:@"completed" options:0 context:nil];
	[_push addObserver:self forKeyPath:@"completed" options:0 context:nil];
	
	
	
	_liveQuery = [[_db getAllDocuments] asLiveQuery];
	_liveQuery.limit = 10;
	_liveQuery.descending = NO;
	[_liveQuery addObserver:self forKeyPath:@"rows" options:0 context:nil];
	
	[self reloadData];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
    if (object == _pull || object == _push) {
        unsigned completed = _pull.completed + _push.completed;
        unsigned total = _pull.total + _push.total;
        if (total > 0 && completed < total) {
			//[self showProgressView];
			//[progressView setProgress: (completed / (float)total)];
			//[SVProgressHUD showWithStatus:@"Sync..."];
			NSLog(@"Syncing");
        } else {
			//[self hideProgressView];
			//[SVProgressHUD dismiss];
			NSLog(@"Done");
			
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
			[people addObject:row.document];
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
    
	CouchDocument *document = [_tableData objectAtIndex:indexPath.row];
	NSString *name = [document propertyForKey:@"name"];
	cell.textLabel.text = name;
    
    return cell;
}

-(NSDictionary*)selectedPerson {
	NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
	CouchDocument *document = [_tableData objectAtIndex:indexPath.row];
	
	return document.properties;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	CouchDocument *document = [_tableData objectAtIndex:indexPath.row];
	RESTOperation *op = [document DELETE];
	[op start];
}


#pragma mark - PersonEditor Delegate

-(void)personEditor:(MAPersonEditorViewController *)personEditor dismissedWithPerson:(NSDictionary *)person {
	RESTOperation *op;
	
	if([[person allKeys] containsObject:@"_id"]) {
		CouchDocument *document = [_db documentWithID:[person objectForKey:@"_id"]];
		op = [document putProperties:person];
	} else {
		CouchDocument *document = [_db untitledDocument];
		op = [document putProperties:person];
	}

	[op start];
}


#pragma mark - Segue Preparation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	NSString *segueIdentifier = segue.identifier;
	
	if([segueIdentifier isEqualToString:@"Add"]) {
		UINavigationController *navigationController = (UINavigationController*)segue.destinationViewController;
		MAPersonEditorViewController *editor = (MAPersonEditorViewController*)[navigationController.viewControllers objectAtIndex:0];
		
		editor.delegate = self;
	} else if([segueIdentifier isEqualToString:@"Edit"]) {
		MAPersonEditorViewController *editor = (MAPersonEditorViewController*)segue.destinationViewController;
		NSDictionary *data = [self selectedPerson];
		editor.data = data;
		editor.delegate = self;
	}
}

@end
