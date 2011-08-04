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

#import "FLTorch.h"


@implementation FLTorch


- (id)init
{
    self = [super init];
    if (self) {
        // Setup a dispatch queue to handle the torch stuff
        _queue = dispatch_queue_create("de.benediktmeurer.FlashLight.Torch", NULL);
        if (!_queue) {
            [self release];
            return nil;
        }
        
        // Perform the initialization asynchronously
        dispatch_async(_queue, ^{
            // Look for a capture device with a torch
            for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
                if ([device hasTorch] && [device isTorchModeSupported:AVCaptureTorchModeOn] && [device isTorchModeSupported:AVCaptureTorchModeOff]) {
                    _device = [device retain];
                    break;
                }
            }
            if (_device) {
                // Setup a session and capture input/output
                _session = [[AVCaptureSession alloc] init];
                if (_session) {
                    AVCaptureOutput *output = [[[AVCaptureVideoDataOutput alloc] init] autorelease];
                    if (output) {
                        NSError *error = nil;
                        AVCaptureInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
                        if (input) {
                            // Configure the device and the session
                            if ([_device lockForConfiguration:&error]) {
                                [_session beginConfiguration];
                                [_session addInput:input];
                                [_session addOutput:output];
                                [_session commitConfiguration];
                                [_device unlockForConfiguration];
                                [_session startRunning];
                            }
                            else {
                                NSLog(@"Failed to lock device %@ for configuration: %@", _device, error);
                                [error release];
                                [_session release], _session = nil;
                                [_device release], _device = nil;
                            }
                        }
                        else {
                            NSLog(@"Failed to setup device %@ as capture input: %@", _device, error);
                            [error release];
                        }
                    }
                }
            }
        });
    }
    return self;
}


- (void)dealloc
{
    dispatch_sync(_queue, ^{
        [_session stopRunning], [_session release], _session = nil;
        [_device release], _device = nil;
    });
    if (_queue) dispatch_release(_queue), _queue = NULL;
    [super dealloc];
}


#pragma mark -
#pragma mark Properties


- (id<FLTorchDelegate>)delegate
{
    __block id<FLTorchDelegate> delegate = nil;
    dispatch_sync(_queue, ^{
        delegate = [_delegate retain];
    });
    return [delegate autorelease];
}


- (void)setDelegate:(id<FLTorchDelegate>)delegate
{
    dispatch_async(_queue, ^{
        _delegate = delegate;
    });
}


- (BOOL)isEnabled
{
    __block BOOL enabled = NO;
    dispatch_sync(_queue, ^{
        enabled = ([_session isRunning] && ([_device torchMode] == AVCaptureTorchModeOn));
    });
    return enabled;
}


- (void)setEnabled:(BOOL)enabled
{
    dispatch_async(_queue, ^{
        NSError *error = nil;
        if ([_device lockForConfiguration:&error]) {
            if (enabled) {
                [_device setTorchMode:AVCaptureTorchModeOn];
            }
            else {
                [_device setTorchMode:AVCaptureTorchModeOff];
            }
            [_device unlockForConfiguration];
            if (![_session isRunning]) {
                [_session startRunning];
            }
        }
        else {
            NSLog(@"Failed to lock device %@ for configuration: %@", _device, error);
            [error release];
        }
        
        if ([_delegate respondsToSelector:@selector(torch:didChangeState:)]) {
            id<FLTorchDelegate> delegate = [[_delegate retain] autorelease];
            BOOL enabled = ([_session isRunning] && ([_device torchMode] == AVCaptureTorchModeOn));
            dispatch_sync(dispatch_get_main_queue(), ^{
                [delegate torch:self didChangeState:enabled];
            });
        }
    });
}


@end
