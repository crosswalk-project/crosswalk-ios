//
//  OBJCObjectFactory.h
//  SwiftFactory
//
//  Created by Joshua Smith on 6/4/14.
//  Copyright (c) 2014 iJoshSmith. All rights reserved.
//

/*
 Be sure to import this file in your project's bridging header file.
 #import "OBJCObjectFactory.h"
 */

@import Foundation;

/** Instantiates NSObject subclasses. */
@interface OBJCObjectFactory : NSObject

/**
 Instantiates the specified class, which must
 descend (dircectly or indirectly) from NSObject.
 Uses the class's parameterless initializer.
 */
+ (id)create:(NSString *)className;

/**
 Instantiates the specified class, which must
 descend (dircectly or indirectly) from NSObject.
 Uses the specified initializer, passing it the
 argument provided via the `argument` parameter.
 */
+ (id)create:(NSString *)className
 initializer:(SEL)initializer
    argument:(id)argument;

@end
