//  Copyright (c) 2014 Scott Talbot. All rights reserved.

@import XCTest;

#import "STXMLBuilder.h"


@interface STXMLBuilderTests : XCTestCase
@end

@implementation STXMLBuilderTests

- (void)testSimple1 {
    id<STXMLBuilderDocument> const doc = [STXMLBuilder document];

    id<STXMLBuilderElement> const r = [doc addChildElementWithNamespacePrefix:@"a" href:@"http://chikachow.org/a" name:@"b"];
    id<STXMLBuilderNamespace> const a = [r namespaceForPrefix:@"a"];
    id<STXMLBuilderNamespace> const b = [r addNamespaceWithPrefix:@"b" href:@"http://chikachow.org/b"];
    id<STXMLBuilderElement> const el1 = [r addChildElementWithNamespace:a name:@"c"];
    id<STXMLBuilderElement> const el2 = [el1 addChildElementWithNamespace:b name:@"d"];
    [el2 addChildElementWithNamespace:a name:@"e"];

    NSData * const data = [doc dataUsingEncoding:NSUTF8StringEncoding];
    NSString * const string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    XCTAssertEqualObjects(string, @"<?xml version=\"1.1\" encoding=\"UTF-8\"?>\n<a:b xmlns:a=\"http://chikachow.org/a\" xmlns:b=\"http://chikachow.org/b\"><a:c><b:d><a:e/></b:d></a:c></a:b>\n");
}

@end
