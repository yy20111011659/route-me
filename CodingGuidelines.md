# Documentation #
Include Doxygen tags for methods, ivars, and classes. Use either a triple comment "///" or a Javadoc style comment "/**!**/".

In Doxygen, the tag goes before the code or element. At a minimum, put a one-line description for each method:
```
/// designated initializer
- (id) initWithAccessKey:(NSString *)developerAccessKey
			 styleNumber:(NSUInteger)styleNumber;

```

If appropriate, provide both a one-liner and a longer description:
```
/*! 
 \brief Wrapper around RMMapContents for the iPhone.
 
 It implements event handling; but that's about it. All the interesting map
 logic is done by RMMapContents. There is exactly one RMMapView instance for each RMMapContents instance.
 
 \bug No accessors for enableDragging, enableZoom, deceleration, decelerationFactor. Changing enableDragging does not change multitouchEnabled for the view.
 */
@interface RMMapView : UIView <RMMapContentsFacade, RMMapContentsAnimationCallback>
```

# Code Repository #

Don't break the trunk. Before you commit code to the trunk, please test it against samples/SampleMap in both Release and Build configurations.

Work on one thing at a time. Each commit should address one specific change. If your commit breaks someone else's project, it's easier for that person to back out a focused commit than to back out a commit that touches bits and pieces of a dozen files.

If your work might break the trunk, then just use a branch for your intermediate commits, and we'll merge it over when you're finished. By convention, we label branches after the bugtracker Issue Number. The code for [Issue 59](https://code.google.com/p/route-me/issues/detail?id=59) is in branches/[issue59](https://code.google.com/p/route-me/issues/detail?id=59).

Long, descriptive commit messages are welcome. If your commit message summarizes what you did, it saves everyone from having to look at the code diffs, or at the Issue Tracker. "consolidated ivars foo, bar, and plugh into xyzzy in class RMContents, closes [issue 982](https://code.google.com/p/route-me/issues/detail?id=982)" is much better than "fixed [issue 982](https://code.google.com/p/route-me/issues/detail?id=982)".

If your commit message pertains to a branch, mention the branch: "59 - allow initial touch to move slightly during marker pickup action".

The issue tracker and source code control system know about each other. If you refer to "[r250](https://code.google.com/p/route-me/source/detail?r=250)" or "[issue 29](https://code.google.com/p/route-me/issues/detail?id=29)" in the issue tracker, commit message, or comments, a hyperlink is set up automatically.

Before adding or removing substantial functionality, lay out your idea on the mailing list. Listen to the feedback you receive. Open a bugtracker ticket, and assign yourself as owner.

# Design Notes #

Route-Me is single-threaded by design. All external calls should come from your main (UI) thread.

# Naming Conventions #

At any moment, you might be referring to a location (on earth, or on your map) by unprojected latitude/longitude, by projected coordinates (generally in meters), or by screen coordinates (in pixels).

Method names and parameters containing LatLng, LatLong, or LatLon refer to an unprojected latitude/longitude, as a CLLocationCoordinate2D type. For future work, use xxxxLatLon. Other forms will be refactored to this spelling shortly after Route-Me 0.5 is released.

Method names and parameters containing XY refer to projected coordinates. As of version 0.4, these are always in meters.

References to screen coordinates use CGPoint types, and generally have the word Screen or Point in the method name.

It is preferable to refer to latitude and longitude, fully spelled out, within your code. Avoid "latlong" because of the possible ambiguity with the long int type.

# Coding Style #

Use properties and accessors whenever possible, especially when setting a instance variable's value. If you're directly calling release on an ivar, you should almost certainly be using the setter/property instead. In your -dealloc method, use your accessors to set each instance variable to nil (that is, "self.foo = nil" or "[setFoo:nil](self.md)", not simply "foo = nil").

There are very few times when direct access to an instance variable is needed. Using accessors is the safest way to ensure that memory management is correct.

Use RMLog() where you might normally want to use NSLog(). RMLog is defined as a macro, so that it works as NSLog in Debug builds, and disappears in Release builds. You may also use LogMethod() if you simply want a method trace logged to the console.

As much as practicable, adhere to Apple Cocoa naming conventions: http://developer.apple.com/DOCUMENTATION/Cocoa/Conceptual/CodingGuidelines/CodingGuidelines.html

Camel case the parameter names, with initial letter lowercase. The preposition "with" should appear at most once in a method name.

Class names are always uppercase, and are always defined in files with the same name as the class.

Use bindings-compatible accessors. If the "setXyzzy" method exists, it must modify the "xyzzy" instance variable of its class.

Following Apple's convention in using spaces in method names.
correct:
- (void)drawRect:(CGRect)aRect

incorrect:
-(void) drawRect: (CGRect) aRect