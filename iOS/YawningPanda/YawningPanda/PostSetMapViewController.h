//
//  PostSetMapViewController.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/24/12.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#define METERS_PER_MILE 1609.344

@interface PostSetMapViewController : UIViewController <MKMapViewDelegate>

@property(strong,nonatomic) IBOutlet MKMapView *mapView;
@property(assign) CLLocationCoordinate2D center;
@property(retain) NSMutableArray *postSet;

@end
