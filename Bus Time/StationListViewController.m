//
//  StationListViewController.m
//  BusTime
//
//  Created by venj on 12-12-18.
//  Copyright (c) 2012年 朱 文杰. All rights reserved.
//

#import "StationListViewController.h"
#import "BusStation.h"
#import "BusRoute.h"
#import "BusDataSource.h"
#import "QueryResultViewController.h"
#import "AppDelegate.h"
#import "ODRefreshControl.h"
#import "HandyFoundation.h"
#import "UIBarButtonItem+Blocks.h"
#import "StationMapViewController.h"
#import "UserDataSource.h"

@interface StationListViewController ()
@property (nonatomic, strong) NSArray *stations;
@property (nonatomic, strong) NSArray *filterStations;
@end

@implementation StationListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.busRoute.segmentName;
    self.searchDisplayController.searchBar.placeholder = NSLocalizedString(@"Bus Name, Pinyin Abbrivation", @"路线名或首字母缩写");
    self.stations = [[BusDataSource shared] stationsForBusRoute:self.busRoute];
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:115./255. green:123./255. blue:143./255. alpha:1];
    StationListViewController *blockSelf = self;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map_icon"] style:UIBarButtonItemStylePlain handler:^(id sender) {
        StationMapViewController *stationVC = [[StationMapViewController alloc] initWithNibName:@"StationMapViewController" bundle:nil];
        stationVC.stations = blockSelf.stations;
        stationVC.title = self.title;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:stationVC];
        nav.modalPresentationStyle = UIModalPresentationPageSheet;
        nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self.navigationController presentModalViewController:nav animated:YES];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    }
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.filterStations count];
    }
    else {
        return [self.stations count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"StationListCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    BusStation *station;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        station = [self.filterStations objectAtIndex:indexPath.row];
    }
    else {
        station = [self.stations objectAtIndex:indexPath.row];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = [NSString stringWithFormat:@"%@. %@", station.stationSequence, station.stationName];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BusStation *station;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        station = [self.filterStations objectAtIndex:indexPath.row];
    }
    else {
        station = [self.stations objectAtIndex:indexPath.row];
    }
    [[UserDataSource shared] addOrUpdateHistoryWithStation:station];
    QueryResultViewController *queryController;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        queryController = [[QueryResultViewController alloc] initWithStyle:UITableViewStyleGrouped];
        queryController.title = [NSString stringWithFormat:@"%@, %@", station.busRoute.segmentName, station.stationName];
        queryController.station = station;
        queryController.userItem = nil;
        [self.navigationController pushViewController:queryController animated:YES];
    }
    else {
        queryController = [[AppDelegate shared] queryResultController];
        queryController.title = [NSString stringWithFormat:@"%@, %@", station.busRoute.segmentName, station.stationName];
        queryController.station = station;
        queryController.userItem = nil;
        [queryController loadResult];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    NSIndexSet *resultSet = [self.stations indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSString *stationName = [(BusStation *)obj stationName];
        NSString *stationNamePY = [(BusStation *)obj stationNamePY];
        NSRange result = [stationName rangeOfString:[searchText strip]];
        if (result.location == NSNotFound) {
            result = [stationNamePY rangeOfString:[searchText strip]];
            return (result.location == NSNotFound) ? NO : YES;
        }
        else {
            return YES;
        }
    }];
    
    self.filterStations = [self.stations objectsAtIndexes:resultSet];
    [self.searchDisplayController.searchResultsTableView reloadData];
}

@end
