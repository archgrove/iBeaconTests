//
//  RSSIGraphViewController.m
//  BeaconTest
//
//  Created by Adam Wright on 27/02/2014.
//  Copyright (c) 2014 Adam Wright. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "../CorePlotHeaders/CorePlot-CocoaTouch.h"

#import "BeaconManager.h"
#import "RSSIGraphViewController.h"
#import "FilteringBeacon.h"

static NSArray const *GraphColours;

@implementation RSSIGraphViewController
{
    __weak IBOutlet CPTGraphHostingView *_graphHost;
    
    BeaconManager *_beaconManager;
    
    // The list of in-range beacons
    NSMutableArray *_beacons;
    // The plots associated with each beacon (matched in index with the _beacons array)
    NSMutableArray *_plots;
    // An array of arrays of CGPoint pairs for the values of each beacon, matched on index with _beacons
    NSMutableArray *_plotValues;
    
    // The start time of the graph, for normalisation
    NSTimeInterval _baseTime;
    
    // The highest time and RSSI we've seen, for graph scaling
    NSTimeInterval _maxTime;
    int _maxRSSI;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // We use the same set of colours for all graphs
    static dispatch_once_t uuidSetup;
    dispatch_once(&uuidSetup, ^{
        GraphColours = @[[UIColor redColor], [UIColor greenColor], [UIColor yellowColor], [UIColor purpleColor],
                         [UIColor blueColor]];
    });

    [self configureGraph];
    
    NSString * const BeaconID = @"EBEFD083-70A2-47C8-9837-E7B5634DF524";
    
    _beaconManager = [BeaconManager managerWithUUIDString:BeaconID];
    _beaconManager.delegate = self;
    _beaconManager.beaconConstructor = ^Beacon*(NSUUID *uuid, NSInteger major, NSInteger minor)
    {
        return [[FilteringBeacon alloc] initWithUUID:uuid major:major minor:minor];
    };
    _beacons = [NSMutableArray array];
    
    _maxTime = 0;
    _maxRSSI = 0;
}

- (void)configureGraph
{
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:_graphHost.bounds];

    graph.borderColor = [UIColor clearColor].CGColor;
    graph.borderWidth = 0;
    [graph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
    _graphHost.hostedGraph = graph;
    
    [graph.axisSet.axes[0] setMinorTickLineStyle:nil];
    [graph.axisSet.axes[1] setMinorTickLineStyle:nil];
    [graph.axisSet.axes[0] setLabelTextStyle:nil];
    [graph.axisSet.axes[1] setLabelTextStyle:nil];
    
    _plots = [NSMutableArray array];
    _plotValues = [NSMutableArray array];
}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot*)plot
{
    int beaconIndex = [_plots indexOfObject:plot];
    
    return [_plotValues[beaconIndex] count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    int beaconIndex = [_plots indexOfObject:plot];
    
    NSMutableArray *plotValueList = (NSMutableArray*)_plotValues[beaconIndex];
    CGPoint p = [plotValueList[index] CGPointValue];
    
    if (fieldEnum == CPTScatterPlotFieldX)
    {
        return @(p.x);
    }
    else
    {
        return @(p.y);
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [_beaconManager startMonitoring];
    _baseTime = [NSDate timeIntervalSinceReferenceDate];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [_beaconManager stopMonitoring];
}

- (void)rangeGraph
{
    // Rescale the graph axes to show all the data
    CPTPlotRange *xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(-1)
                                                        length:CPTDecimalFromFloat(_maxTime + 1)];
    CPTPlotRange *yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(-1)
                                                        length:CPTDecimalFromFloat(_maxRSSI + 5)];
    
    [_graphHost.hostedGraph.defaultPlotSpace setPlotRange:xRange forCoordinate:CPTCoordinateX];
    [_graphHost.hostedGraph.defaultPlotSpace setPlotRange:yRange forCoordinate:CPTCoordinateY];
}

- (void)logRSSIForBeacon:(Beacon*)b
{
    // Log the time and RSSI of the given beacon
    int index = [_beacons indexOfObject:b];
    
    NSTimeInterval localTime = [NSDate timeIntervalSinceReferenceDate] - _baseTime;
    int localRSSI = -(b.RSSI);
    
    if (localTime > _maxTime)
        _maxTime = localTime;
    
    if (localRSSI > _maxRSSI)
        _maxRSSI = localRSSI;
    
    [_plotValues[index] addObject:[NSValue valueWithCGPoint:CGPointMake(localTime, localRSSI)]];
    
    [self rangeGraph];
    [_graphHost.hostedGraph reloadData];
}

- (CPTLineStyle*)nextLineStyle
{
    // Grab the next colour to use in the graph, and build a line styling from it
    UIColor *nextColour = GraphColours[_beacons.count % GraphColours.count];
    
    CPTMutableLineStyle *style = [[CPTMutableLineStyle alloc] init];
    
    style.lineColor = [CPTColor colorWithCGColor:nextColour.CGColor];
    
    return style;
}

#pragma mark - Beacon manager delegate

- (void)beaconManager:(BeaconManager *)beaconManager discoveredBeacon:(Beacon *)newBeacon
{
    // Add a graph for this new beacon
    CPTScatterPlot *beaconPlot = [[CPTScatterPlot alloc] initWithFrame:_graphHost.hostedGraph.plotAreaFrame.bounds];
    beaconPlot.dataSource = self;
    beaconPlot.dataLineStyle = [self nextLineStyle];
    [_graphHost.hostedGraph addPlot:beaconPlot];
    
    [_beacons addObject:newBeacon];
    [_plots addObject:beaconPlot];
    [_plotValues addObject:[NSMutableArray array]];
    
    [self logRSSIForBeacon:newBeacon];
}

- (void)beaconManager:(BeaconManager *)beaconManager lostBeacon:(Beacon *)lostBeacon
{
    // Remove the graph for this beacon
    NSInteger beaconIndex = [_beacons indexOfObject:lostBeacon];
    
    [_graphHost.hostedGraph removePlot:_plots[beaconIndex]];
    
    [_beacons removeObjectAtIndex:beaconIndex];
    [_plots removeObjectAtIndex:beaconIndex];
    [_plotValues removeObjectAtIndex:beaconIndex];
}

- (void)beaconManager:(BeaconManager *)beaconManager updatedBeacon:(Beacon *)beacon
{
    // Update the beacon data
    [self logRSSIForBeacon:beacon];
}


@end
