//  Copyright (c) 2014 Scott Talbot. All rights reserved.

@import XCTest;

#import "STXMLDocument.h"


@interface STXMLDocumentTests : XCTestCase
@end

@implementation STXMLDocumentTests

- (void)testSimpleInstantiation {
    STXMLDocument * const doc = [[STXMLDocument alloc] init];
    XCTAssertNotNil(doc, @"");
}

@end
