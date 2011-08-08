/*-
 * Copyright (c) 2011, Benedikt Meurer <benedikt.meurer@googlemail.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#import "FLRootViewController.h"


@interface FLRootViewController ()

- (void)applicationDidBecomeActiveNotification:(NSNotification *)notification;
- (void)synchronize;

@end


@implementation FLRootViewController

@synthesize ledImageView = _ledImageView;
@synthesize switchView = _switchView;
@synthesize touchView = _touchView;
@synthesize torch = _torch;


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_ledImageView release], _ledImageView = nil;
    [_switchView release], _switchView = nil;
    [_touchView setDelegate:nil];
    [_touchView release], _touchView = nil;
    [_torch setDelegate:nil];
    [_torch release], _torch = nil;
    if (_tickSoundRegistered) {
        AudioServicesDisposeSystemSoundID(_tickSoundID);
        _tickSoundRegistered = NO;
    }
    [super dealloc];
}


#pragma mark -
#pragma mark Properties


- (FLTorch *)torch
{
    if (!_torch) {
        _torch = [[FLTorch alloc] init];
        _torch.delegate = self;
    }
    return _torch;
}


#pragma mark -
#pragma mark Actions


- (IBAction)infoButtonClicked:(id)sender
{
    FLInfoViewController *infoViewController = [[FLInfoViewController alloc] initWithNibName:@"InfoViewController" bundle:nil];
    infoViewController.delegate = self;
    [self presentModalViewController:infoViewController animated:YES];
    [infoViewController release];
}


#pragma mark -
#pragma mark Private


- (void)applicationDidBecomeActiveNotification:(NSNotification *)notification
{
    [self performSelectorOnMainThread:@selector(synchronize) withObject:nil waitUntilDone:NO];
}


- (void)synchronize
{
    CGSize touchViewSize = [self.touchView frame].size;
    CGRect switchViewFrame = [self.switchView frame];
    [self.torch setEnabled:(switchViewFrame.origin.y + switchViewFrame.size.height / 2.0f < touchViewSize.height / 2.0f)];
}


#pragma mark -
#pragma mark FLInforViewControllerDelegate


- (void)infoViewControllerDidFinish:(FLInfoViewController *)infoViewController
{
    [infoViewController dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark FLTouchViewDelegate


- (void)touchView:(FLTouchView *)touchView touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_touchActive) {
        [self touchView:touchView touchesEnded:touches withEvent:event];
    }
    CGPoint location = [[touches anyObject] locationInView:touchView];
    if (CGRectContainsPoint([_switchView frame], location)) {
        _touchActive = YES;
        [self touchView:touchView touchesMoved:touches withEvent:event];
    }
}


- (void)touchView:(FLTouchView *)touchView touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchView:touchView touchesEnded:touches withEvent:event];
}


- (void)touchView:(FLTouchView *)touchView touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_touchActive) {
        CGPoint location = [[touches anyObject] locationInView:touchView];
        CGSize touchViewSize = [touchView frame].size;
        CGRect switchViewFrame = [self.switchView frame];
        switchViewFrame.origin.y = location.y - switchViewFrame.size.height / 2.0f;
        if (switchViewFrame.origin.y + switchViewFrame.size.height / 2.0f < touchViewSize.height / 2.0f) {
            switchViewFrame.origin.y = 0.0f;
        }
        else {
            switchViewFrame.origin.y = [self.touchView frame].size.height - switchViewFrame.size.height;
        }
        [UIView animateWithDuration:0.1f animations:^{
            [self.switchView setFrame:switchViewFrame];
        }];
        [self synchronize];
        _touchActive = NO;
    }
}


- (void)touchView:(FLTouchView *)touchView touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_touchActive) {
        CGPoint location = [[touches anyObject] locationInView:touchView];
        CGSize touchViewSize = [touchView frame].size;
        CGRect switchViewFrame = [_switchView frame];
        switchViewFrame.origin.y = location.y - switchViewFrame.size.height / 2.0f;
        if (switchViewFrame.origin.y < 0.0f) {
            switchViewFrame.origin.y = 0.0f;
        }
        else if (switchViewFrame.origin.y + switchViewFrame.size.height > touchViewSize.height) {
            switchViewFrame.origin.y = touchViewSize.height - switchViewFrame.size.height;
        }
        [self.switchView setFrame:switchViewFrame];
        [self synchronize];
    }
}


#pragma mark -
#pragma mark FLTorchDelegate


- (void)torch:(FLTorch *)torch didChangeState:(BOOL)enabled
{
    if ([self.ledImageView isHidden] != !enabled) {
        [self.ledImageView setHidden:!enabled];
        if (!_tickSoundRegistered) {
            CFURLRef tickSoundURL = (CFURLRef)[[NSBundle mainBundle] URLForResource:@"Tick" withExtension:@"caf"];
            if (tickSoundURL && AudioServicesCreateSystemSoundID(tickSoundURL, &_tickSoundID) == kAudioServicesNoError) {
                _tickSoundRegistered = YES;
            }
        }
        if (_tickSoundRegistered) {
            AudioServicesPlaySystemSound(_tickSoundID);
        }
    }
}


#pragma mark -
#pragma mark UIViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self synchronize];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.ledImageView = nil;
    self.switchView = nil;
    self.touchView.delegate = nil;
    self.touchView = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


@end
