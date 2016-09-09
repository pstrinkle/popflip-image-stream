//
//  PostLocationViewController.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 8/27/12.
//
//

#import "PostLocationViewController.h"

@interface PostLocationViewController ()

@end

@implementation PostLocationViewController

@synthesize mapView;
@synthesize center;
@synthesize postInfo;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.center, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
    
    [self.mapView setRegion:adjustedRegion animated:YES];
    [self.mapView addAnnotation:self.postInfo];
    
    NSLog(@"Map of %@", self.mapView);
    
//    self.mapView.centerCoordinate = center;

    return;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.mapView.delegate = self;
    
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    self.mapView.centerCoordinate = userLocation.location.coordinate;
    
    return;
}

/**
 * @brief This is called for each annotation, similarly to the cell is a 
 * UITableView.
 */
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    static NSString *identifier = @"Location";

    MKPinAnnotationView *annotationView = \
        (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    
    if (annotationView == nil)
    {
        annotationView =
            [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                             reuseIdentifier:identifier];
    }
    else
    {
        annotationView.annotation = annotation;
    }
        
    annotationView.enabled = YES;

    return annotationView;
}

@end
