//  Copyright (c) 2014 Scott Talbot. All rights reserved.

@import XCTest;

#import "STXMLDocument.h"


@interface STXMLDocumentTests : XCTestCase
@end

@implementation STXMLDocumentTests

- (void)testSimpleInstantiation1 {
    NSError *error = nil;
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:[@" " dataUsingEncoding:NSUTF8StringEncoding] error:&error];
    XCTAssertNil(doc, @"");
    XCTAssertNotNil(error, @"");
    XCTAssertEqual(error.code, 0x10004, @"");
}
- (void)testSimpleInstantiation2 {
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:[@"" dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertNil(doc, @"");
}
- (void)testSimpleInstantiation3 {
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:[@"<foo/>" dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertNotNil(doc, @"");
}

- (void)testRootName1 {
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:[@"<foo/>" dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertNotNil(doc, @"");
    STXMLElement * const root = doc.rootElement;
    XCTAssertNotNil(root, @"");
    XCTAssertEqualObjects(root.name, @"foo", @"");
}
- (void)testRootName2 {
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:[@"<foo:foo xmlns:foo=\"http://xmlns.chikachow.org/foo\"/>" dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertNotNil(doc, @"");
    STXMLElement * const root = doc.rootElement;
    XCTAssertNotNil(root, @"");
    XCTAssertEqualObjects(root.name, @"foo", @"");
}

- (void)testRootContent1 {
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:[@"<foo>bar</foo>" dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertNotNil(doc, @"");
    STXMLElement * const root = doc.rootElement;
    XCTAssertNotNil(root, @"");
    XCTAssertEqualObjects(root.content, @"bar", @"");
}

- (void)testRootContent2 {
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:[@"<?qux quux=\"quuux\"?><!--bar--><foo/>" dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertNotNil(doc, @"");
    STXMLElement * const root = doc.rootElement;
    XCTAssertNotNil(root, @"");
    XCTAssertEqualObjects(root.content, @"", @"");

    STXMLNode * const pi = doc.children[0];
    XCTAssertNotNil(pi, @"");
    XCTAssertEqual(pi.type, STXMLNodeTypePI, @"");
    XCTAssertEqualObjects(pi.content, @"quux=\"quuux\"", @"");

    STXMLNode * const comment = doc.children[1];
    XCTAssertNotNil(comment, @"");
    XCTAssertEqual(comment.type, STXMLNodeTypeCOMMENT, @"");
    XCTAssertEqualObjects(comment.content, @"bar", @"");
}

- (void)testChildrenPassingTest1 {
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:[@"<foo><a>.</a><b/><c>,</c></foo>" dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertNotNil(doc, @"");
    STXMLElement * const root = doc.rootElement;
    XCTAssertNotNil(root, @"");
    NSArray * const childrenPassingTest = [root childrenPassingTest:^BOOL(STXMLNode *node, BOOL *stop) {
        if ([@"a" isEqualToString:node.name]) {
            return YES;
        }
        if ([@"c" isEqualToString:node.name]) {
            return YES;
        }
        return NO;
    }];
    XCTAssertEqual(childrenPassingTest.count, 2, @"");

    XCTAssertEqualObjects(((STXMLNode *)childrenPassingTest[0]).name, @"a", @"");
    XCTAssertEqualObjects(((STXMLNode *)childrenPassingTest[0]).content, @".", @"");
    XCTAssertEqualObjects(((STXMLNode *)childrenPassingTest[1]).name, @"c", @"");
    XCTAssertEqualObjects(((STXMLNode *)childrenPassingTest[1]).content, @",", @"");
}

- (void)testChildrenPassingTest2 {
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:[@"<foo><a/><b/><a/></foo>" dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertNotNil(doc, @"");
    STXMLElement * const root = doc.rootElement;
    XCTAssertNotNil(root, @"");
    NSArray * const childrenPassingTest = [root childrenPassingTest:STXMLNodeHasName(@"a")];
    XCTAssertEqual(childrenPassingTest.count, 2, @"");
}

- (void)testAttributes1 {
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:[@"<foo a=\"b\"/>" dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertNotNil(doc, @"");
    STXMLElement * const root = doc.rootElement;
    XCTAssertNotNil(root, @"");
    NSArray * const attributesPassingTest = [root attributesPassingTest:STXMLNodeHasName(@"a")];
    XCTAssertEqual(attributesPassingTest.count, 1, @"");
    STXMLAttribute * const attribute = attributesPassingTest.firstObject;
    XCTAssertEqualObjects(attribute.name, @"a", @"");
    XCTAssertEqualObjects(attribute.content, @"b", @"");
}

- (void)testXPath1 {
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:[@"<a><b/><c><d>e</d></c><f/></a>" dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertNotNil(doc, @"");
    STXPathNodeSetResult * const result = (STXPathNodeSetResult *)[doc resultByEvaluatingXPathExpression:@"//a/c/d"];
    XCTAssertNotNil(result, @"");
    id const xpathResultNodeContent = [result.nodes.firstObject content];
    XCTAssertEqualObjects(xpathResultNodeContent, @"e", @"");
    (void)xpathResultNodeContent;
}

@end