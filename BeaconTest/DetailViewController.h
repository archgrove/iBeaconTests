//
//  DetailViewController.h
//  BeaconTest
//
//  Created by Adam Wright on 10/02/2014.
//  Copyright (c) 2014 Adam Wright. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
