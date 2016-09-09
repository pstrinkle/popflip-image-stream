//
//  PostSetMapViewController.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/24/12.
//
//

#import "PostSetMapViewController.h"
#import "Post.h"

@implementation PostSetMapViewController

@synthesize postSet;
@synthesize mapView;
@synthesize center;

- (IBAction)dismiss
{
    NSLog(@"Dismissing.");
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)action:(UISegmentedControl *)actionSheetBtn
{
    MKMapType type = self.mapView.mapType;
    
    //actionSheetBtn.backgroundColor = [UIColor blueColor];
    //[actionSheetBtn setSelected:YES];
    
//    actionSheetBtn.highlighted = YES;
//    actionSheetBtn.selected = YES;
    
    switch (actionSheetBtn.selectedSegmentIndex)
    {
        case 0:
            type = MKMapTypeStandard;
            break;
        case 1:
            type = MKMapTypeSatellite;
            break;
        case 2:
            type = MKMapTypeHybrid;
            break;
    }
    
    if (type == self.mapView.mapType)
    {
        return;
    }
    
    self.mapView.mapType = type;

    return;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self)
    {
        // Custom initialization
        self.postSet = [[NSMutableArray alloc] init];
        self.mapView.delegate = self;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    bool centerSet = NO;
    
    /* XXX: I want them to be selectable and have tiles for thumbnails. */
    for (Post *obj in self.postSet)
    {
        if (obj.validCoordinates)
        {
            [self.mapView addAnnotation:obj];

            if (centerSet == NO)
            {
                self.center = obj.coordinate;
                centerSet = YES;
            }
        }
    }
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.center, 10*METERS_PER_MILE, 10*METERS_PER_MILE);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
    
    [self.mapView setRegion:adjustedRegion animated:YES];
    
    UIBarButtonItem *backBtn = \
        [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                         style:UIBarButtonItemStyleDone
                                        target:self
                                        action:@selector(dismiss)];
    
    self.navigationItem.leftBarButtonItem = backBtn;
    self.navigationItem.title = [NSString stringWithFormat:@"%d Posts", [self.mapView.annotations count]];

    UIToolbar *topBar = \
        [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.mapView.bounds.origin.y,
                                                    self.mapView.bounds.size.width, 40)];
    topBar.barStyle = UIBarStyleBlackTranslucent;
    topBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    UISegmentedControl *mapTypeControl = \
        [[UISegmentedControl alloc] initWithItems:@[@"Normal", @"Satellite", @"Hybrid"]];

    mapTypeControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    mapTypeControl.momentary = NO;
    [mapTypeControl setSelectedSegmentIndex:0];
    mapTypeControl.segmentedControlStyle = UISegmentedControlStyleBar;
    mapTypeControl.tintColor = [UIColor clearColor];
    mapTypeControl.frame = CGRectMake(10, self.mapView.bounds.origin.y + 5,
                                      self.mapView.bounds.size.width - 20, 30);

    [mapTypeControl addTarget:self
                    action:@selector(action:)
          forControlEvents:UIControlEventValueChanged];

    UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithCustomView:mapTypeControl];
    topBar.items = @[btn];
    
    [self.view addSubview:topBar];

    return;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
