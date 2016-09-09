//
//  PostLocationViewController.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 8/27/12.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Post.h"

#define METERS_PER_MILE 1609.344

@interface PostLocationViewController : UIViewController <MKMapViewDelegate>

@property(strong,nonatomic) IBOutlet MKMapView *mapView;
@property(assign) CLLocationCoordinate2D center;

@property(copy) Post *postInfo;

@end
