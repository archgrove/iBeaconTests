//
//  RSSIGraphViewController.h
//  BeaconTest
//
//  Created by Adam Wright on 27/02/2014.
//  Copyright (c) 2014 Adam Wright. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "../CorePlotHeaders/CorePlot-CocoaTouch.h"

@interface RSSIGraphViewController : UIViewController<CPTPlotDataSource, CLLocationManagerDelegate,
                                                      BeaconManagerDelegate>
@end
