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

#import "FLInfoViewController.h"


@implementation FLInfoViewController

@synthesize delegate = _delegate;
@synthesize titleLabel = _titleLabel;
@synthesize versionLabel = _versionLabel;


- (void)dealloc
{
    [_titleLabel release], _titleLabel = nil;
    [_versionLabel release], _versionLabel = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Actions


- (IBAction)doneBarButtonItemClicked:(id)sender
{
    [self.delegate infoViewControllerDidFinish:self];
}


#pragma mark -
#pragma mark UIViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"InfoBackground"]]];
    
    // Generate the titleLabel and versionLabel from the Info.plist strings
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    self.titleLabel.text = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    self.versionLabel.text = [NSString stringWithFormat:@"%@ (%@)",
                              [infoDictionary objectForKey:@"CFBundleShortVersionString"],
                              [infoDictionary objectForKey:@"CFBundleVersion"]];

}


- (void)viewDidUnload
{
    [super viewDidUnload];
    self.titleLabel = nil;
    self.versionLabel = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


@end
