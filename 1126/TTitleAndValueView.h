//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Jun  9 2015 22:53:21).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2014 by Steve Nygard.
//

#import "TUpdateLayerView.h"

@class NSLayoutConstraint, NSView, TTextField;

@interface TTitleAndValueView : TUpdateLayerView
{
    struct TNSRef<TTextField, void> _titleField;
    struct TNSRef<NSView, void> _valueView;
    struct TNSRef<NSMutableArray<NSLayoutConstraint *>, void> _constraints;
    NSLayoutConstraint *_titleAndValueGapConstraint;
    double _titleAndValueGap;
    double _valueViewBottomInset;
    _Bool _loadedFromNib;
}

@property(nonatomic) double valueViewBottomInset; // @synthesize valueViewBottomInset=_valueViewBottomInset;
- (id).cxx_construct;
- (void).cxx_destruct;
- (void)updateValueViewAXTitle;
- (void)_updateInternalConstraints;
@property(nonatomic) double titleAndValueGap; // @dynamic titleAndValueGap;
@property(retain, nonatomic) NSView *valueView; // @dynamic valueView;
@property(retain, nonatomic) TTextField *titleField; // @dynamic titleField;
- (void)awakeFromNib;
- (void)initCommon;

@end
