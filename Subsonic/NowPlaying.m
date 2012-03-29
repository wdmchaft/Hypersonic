//
//  NowPlaying.m
//  Subsonic
//
//  Created by Josh Betz on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NowPlaying.h"
#import "AppDelegate.h"
#import <AVFoundation/AVPlayerItem.h>
#import <AVFoundation/AVPlayer.h>
#import <AVFoundation/AVAudioSession.h>
#import <MediaPlayer/MPVolumeView.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <MediaPlayer/MPMediaItemCollection.h>

@interface NowPlaying ()
@end

@implementation NowPlaying
@synthesize songID, playerItem, playButton, userName, userPassword, serverURL, albumArt, reflectionImage, albumArtID, nextButton, prevButton, volumeSlider;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)viewDidLoad
{
    if(songList.count > 0 && differentAlbum == true) {
        [self buildPlaylist];
        avPlayer = [[AVQueuePlayer alloc] initWithItems:itemList];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive: YES error: nil];
        
        for ( int i=0; i < currentIndex; i++ )
            [avPlayer removeItem:[itemList objectAtIndex:i]];
                
        [self playSong:playButton];
        differentAlbum = false;
    }
    else if (differentAlbum == false) {
        if (art != nil){
            albumArt.image = art;
        }
    }
    //AVPlayerLayer *avPlayerLayer = [[AVPlayerLayer playerLayerWithPlayer:avPlayer] retain];
    //[avPlayer play];
    //avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(20,380,280,20)];
    [volumeView sizeToFit];
    [self.view addSubview:volumeView];

    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    if (avPlayer.rate > 0)
        [playButton setTitle:@"Pause" forState:UIControlStateNormal];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //Once the view has loaded then we can register to begin recieving controls and we can become the first responder
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    //End recieving events
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
}

//Make sure we can recieve remote control events
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    //if it is a remote control event handle it correctly
    if (event.type == UIEventTypeRemoteControl) {
        if (event.subtype == UIEventSubtypeRemoteControlPlay) {
            [self playSong:playButton];
        } else if (event.subtype == UIEventSubtypeRemoteControlPause) {
            [self playSong:playButton];
        } else if (event.subtype == UIEventSubtypeRemoteControlTogglePlayPause) {
            [self playSong:playButton];
        } else if (event.subtype == UIEventSubtypeRemoteControlNextTrack) {
            [self nextSong:nextButton];
        } else if (event.subtype == UIEventSubtypeRemoteControlPreviousTrack) {
            [self prevSong:prevButton];
        }
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    [self nextSong:nextButton];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

// iOS5 Only
- (void) setMediaInfo {
    Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
    
    if (playingInfoCenter) {
        MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
        MPMediaItemArtwork *artwork = nil;
        if( albumArtID != nil) {
            artwork = [[MPMediaItemArtwork alloc] initWithImage:art];
        }
        NSDictionary *songInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"Some artist", MPMediaItemPropertyArtist,
                                  @"Some title", MPMediaItemPropertyTitle,
                                  @"Some Album", MPMediaItemPropertyAlbumTitle,
                                  artwork, MPMediaItemPropertyArtwork,
                                  nil];
        center.nowPlayingInfo = songInfo;
    }
}

- (void)buildPlaylist {
    queueList = [NSMutableArray array];
    itemList = [NSMutableArray array];
    NSString *userURL;
    NSURL *url;
    for (int i = 0; i < [songList count]; i++){
        userURL = @"http://";
        userURL = [userURL stringByAppendingString:server];
        userURL = [userURL stringByAppendingString:@"/rest/stream.view?u="];
        userURL = [userURL stringByAppendingString:name];
        userURL = [userURL stringByAppendingString:@"&p="];
        userURL = [userURL stringByAppendingString:password];
        userURL = [userURL stringByAppendingString:@"&v=1.1.0&c=Hypersonic&id="];
        userURL = [userURL stringByAppendingString:[[songList objectAtIndex:i] songID]];
        url = [NSURL URLWithString:userURL];
        [queueList addObject:url];
    }
    if (albumArtID != nil) {
        userURL = @"http://";
        userURL = [userURL stringByAppendingString:server];
        userURL = [userURL stringByAppendingString:@"/rest/getCoverArt.view?u="];
        userURL = [userURL stringByAppendingString:name];
        userURL = [userURL stringByAppendingString:@"&p="];
        userURL = [userURL stringByAppendingString:password];
        userURL = [userURL stringByAppendingString:@"&v=1.1.0&c=Hypersonic&id="];
        userURL = [userURL stringByAppendingString:albumArtID];
        
        NSURL *imageURL = [NSURL URLWithString: userURL];
        NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
        UIImage *image = [UIImage imageWithData:imageData]; 
        albumArt.image = image;
        art = image;
        
        NSUInteger reflectionHeight = albumArt.bounds.size.height * 0.65;
        reflectionImage.image = [self reflectedImage:albumArt withHeight:reflectionHeight];
        reflectionImage.alpha = 0.60;
    }
    
    NSLog(@"%d", [queueList count]);
    for (int i = 0; i < [queueList count]; i++){
        url = [queueList objectAtIndex:i];
        [itemList addObject:[AVPlayerItem playerItemWithURL:url]];
    }
}

- (IBAction)done:(id)sender
{  
    [self dismissModalViewControllerAnimated:YES];
}

-(IBAction)playSong:(id)sender{
    if ([itemList count] > 0){
        if (avPlayer.rate == 0.0){
            UIBackgroundTaskIdentifier newTaskId = UIBackgroundTaskInvalid;
            [avPlayer play];
            newTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:NULL];
            [playButton setTitle:@"Pause" forState:UIControlStateNormal];
        }   
        else {
            [avPlayer pause];
            [playButton setTitle:@"Play" forState:UIControlStateNormal];
        }
    }
    [self setMediaInfo];
}

-(IBAction)nextSong:(id)nextButton{
    [avPlayer advanceToNextItem];
    currentIndex++;
}


-(IBAction)prevSong:(id)prevButton{
    currentIndex--;
    
    [self buildPlaylist];
    
    UIBackgroundTaskIdentifier newTaskId = UIBackgroundTaskInvalid;
    avPlayer = [[AVQueuePlayer alloc] initWithItems:itemList];
    
    for ( int i=0; i < currentIndex; i++ )
        [avPlayer removeItem:[itemList objectAtIndex:i]];
    
    [avPlayer play];
    
    newTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:NULL];
}

-(void)adjustVolume
{
    if (avPlayer != nil)
    {
        //[avPlayer set = volumeSlider.value;
    }
} 

#pragma mark - Image Reflection

CGImageRef CreateGradientImage(int pixelsWide, int pixelsHigh)
{
    CGImageRef theCGImage = NULL;
    
    // gradient is always black-white and the mask must be in the gray colorspace
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    // create the bitmap context
    CGContextRef gradientBitmapContext = CGBitmapContextCreate(NULL, pixelsWide, pixelsHigh,
                                                               8, 0, colorSpace, kCGImageAlphaNone);
    
    // define the start and end grayscale values (with the alpha, even though
    // our bitmap context doesn't support alpha the gradient requires it)
    CGFloat colors[] = {0.0, 1.0, 1.0, 1.0};
    
    // create the CGGradient and then release the gray color space
    CGGradientRef grayScaleGradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
    CGColorSpaceRelease(colorSpace);
    
    // create the start and end points for the gradient vector (straight down)
    CGPoint gradientStartPoint = CGPointZero;
    CGPoint gradientEndPoint = CGPointMake(0, pixelsHigh);
    
    // draw the gradient into the gray bitmap context
    CGContextDrawLinearGradient(gradientBitmapContext, grayScaleGradient, gradientStartPoint,
                                gradientEndPoint, kCGGradientDrawsAfterEndLocation);
    CGGradientRelease(grayScaleGradient);
    
    // convert the context into a CGImageRef and release the context
    theCGImage = CGBitmapContextCreateImage(gradientBitmapContext);
    CGContextRelease(gradientBitmapContext);
    
    // return the imageref containing the gradient
    return theCGImage;
}

CGContextRef MyCreateBitmapContext(int pixelsWide, int pixelsHigh)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create the bitmap context
    CGContextRef bitmapContext = CGBitmapContextCreate (NULL, pixelsWide, pixelsHigh, 8,
                                                        0, colorSpace,
                                                        // this will give us an optimal BGRA format for the device:
                                                        (kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst));
    CGColorSpaceRelease(colorSpace);
    
    return bitmapContext;
}

- (UIImage *)reflectedImage:(UIImageView *)fromImage withHeight:(NSUInteger)height
{
    if(height == 0)
        return nil;
    
    // create a bitmap graphics context the size of the image
    CGContextRef mainViewContentContext = MyCreateBitmapContext(fromImage.bounds.size.width, height);
    
    // create a 2 bit CGImage containing a gradient that will be used for masking the 
    // main view content to create the 'fade' of the reflection.  The CGImageCreateWithMask
    // function will stretch the bitmap image as required, so we can create a 1 pixel wide gradient
    CGImageRef gradientMaskImage = CreateGradientImage(1, height);
    
    // create an image by masking the bitmap of the mainView content with the gradient view
    // then release the  pre-masked content bitmap and the gradient bitmap
    CGContextClipToMask(mainViewContentContext, CGRectMake(0.0, 0.0, fromImage.bounds.size.width, height), gradientMaskImage);
    CGImageRelease(gradientMaskImage);
    
    // In order to grab the part of the image that we want to render, we move the context origin to the
    // height of the image that we want to capture, then we flip the context so that the image draws upside down.
    CGContextTranslateCTM(mainViewContentContext, 0.0, height);
    CGContextScaleCTM(mainViewContentContext, 1.0, -1.0);
    
    // draw the image into the bitmap context
    CGContextDrawImage(mainViewContentContext, fromImage.bounds, fromImage.image.CGImage);
    
    // create CGImageRef of the main view bitmap content, and then release that bitmap context
    CGImageRef reflectionImage = CGBitmapContextCreateImage(mainViewContentContext);
    CGContextRelease(mainViewContentContext);
    
    // convert the finished reflection image to a UIImage 
    UIImage *theImage = [UIImage imageWithCGImage:reflectionImage];
    
    // image is retained by the property setting above, so we can release the original
    CGImageRelease(reflectionImage);
    
    return theImage;
}

@end