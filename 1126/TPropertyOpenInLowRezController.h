//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Jun  9 2015 22:53:21).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2014 by Steve Nygard.
//

#import "TPropertyButtonController.h"

@class NSLayoutConstraint, TUpdateLayerView;

@interface TPropertyOpenInLowRezController : TPropertyButtonController
{
    struct TNotificationCenterObserver _finderPrefsChangedObserver;
    NSLayoutConstraint *_leadingConstraint;
    TUpdateLayerView *_wrapperView;
}

@property(readonly, retain, nonatomic) TUpdateLayerView *wrapperView; // @synthesize wrapperView=_wrapperView;
- (id).cxx_construct;
- (void).cxx_destruct;
@property(nonatomic) double leadingConstraintConstant; // @dynamic leadingConstraintConstant;
- (void)preferencesChanged;
- (void)initCommon;

@end
