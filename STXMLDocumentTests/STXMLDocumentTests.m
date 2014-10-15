//  Copyright (c) 2014 Scott Talbot. All rights reserved.

#import <XCTest/XCTest.h>

#import "STXMLDocument.h"


@interface STXMLDocumentTests : XCTestCase
@end

@implementation STXMLDocumentTests

- (void)testSimpleInstantiation1 {
    NSError *error = nil;
    NSData * const input = [@" " dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:input error:&error];
    XCTAssertNil(doc, @"");
    XCTAssertNotNil(error, @"");
    XCTAssertEqual(error.code, 0x10004, @"");
}
- (void)testSimpleInstantiation2 {
    NSData * const input = [@"" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:input];
    XCTAssertNil(doc, @"");
}
- (void)testSimpleInstantiation3 {
    NSData * const input = [@"<foo/>" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion: false];
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:input];
    XCTAssertNotNil(doc, @"");
}

- (void)testRootName1 {
    NSData * const input = [@"<foo/>" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion: false];
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:input];
    XCTAssertNotNil(doc, @"");
    STXMLElement * const root = doc.rootElement;
    XCTAssertNotNil(root, @"");
    XCTAssertEqualObjects(root.name, @"foo", @"");
}
- (void)testRootName2 {
    NSData * const input = [@"<foo:foo xmlns:foo=\"http://xmlns.chikachow.org/foo\"/>" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion: false];
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:input];
    XCTAssertNotNil(doc, @"");
    STXMLElement * const root = doc.rootElement;
    XCTAssertNotNil(root, @"");
    XCTAssertEqualObjects(root.name, @"foo", @"");
}

- (void)testRootContent1 {
    NSData * const input = [@"<foo>bar</foo>" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion: false];
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:input];
    XCTAssertNotNil(doc, @"");
    STXMLElement * const root = doc.rootElement;
    XCTAssertNotNil(root, @"");
    XCTAssertEqualObjects(root.content, @"bar", @"");
}
- (void)testRootContent2 {
    NSData * const input = [@"<?qux quux=\"quuux\"?><!--bar--><foo/>" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion: false];
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:input];
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
    NSData * const input = [@"<foo><a>.</a><b/><c>,</c></foo>" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion: false];
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:input];
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

    XCTAssertEqualObjects(((STXMLElement *)childrenPassingTest[0]).name, @"a", @"");
    XCTAssertEqualObjects(((STXMLElement *)childrenPassingTest[0]).content, @".", @"");
    XCTAssertEqualObjects(((STXMLElement *)childrenPassingTest[1]).name, @"c", @"");
    XCTAssertEqualObjects(((STXMLElement *)childrenPassingTest[1]).content, @",", @"");
}
- (void)testChildrenPassingTest2 {
    NSData * const input = [@"<foo><a/><b/><a/></foo>" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion: false];
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:input];
    XCTAssertNotNil(doc, @"");
    STXMLElement * const root = doc.rootElement;
    XCTAssertNotNil(root, @"");
    NSArray * const childrenPassingTest = [root childrenPassingTest:^BOOL(STXMLNode *node, BOOL *stop) {
        if ([@"a" isEqualToString:node.name]) {
            return YES;
        }
        return NO;
    }];
    XCTAssertEqual(childrenPassingTest.count, 2, @"");
}

- (void)testAttributes1 {
    NSData * const input = [@"<foo a=\"b\"/>" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion: false];
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:input];
    XCTAssertNotNil(doc, @"");
    STXMLElement * const root = doc.rootElement;
    XCTAssertNotNil(root, @"");

    NSArray * const attributesPassingTest = [root attributesPassingTest:^BOOL(STXMLNode *node, BOOL *stop) {
        if ([@"a" isEqualToString:node.name]) {
            return YES;
        }
        return NO;
    }];
    XCTAssertEqual(attributesPassingTest.count, 1, @"");

    STXMLAttribute * const attribute = attributesPassingTest.firstObject;
    XCTAssertEqualObjects(attribute.name, @"a", @"");
    XCTAssertEqualObjects(attribute.content, @"b", @"");

    NSArray * const attributesPassingTest2 = [root attributesPassingTest:^BOOL(STXMLNode *node, BOOL *stop) {
    STXMLAttribute * const attribute = (STXMLAttribute *)([node isKindOfClass:[STXMLAttribute class]] ? node : nil);
        return [@"a" isEqualToString:attribute.name];
    }];
    XCTAssertEqualObjects(attributesPassingTest, attributesPassingTest2, @"");
}

- (void)testNamespaces1 {
    NSData * const input = [@"<foo:foo xmlns:foo=\"http://xmlns.chikachow.org/foo\">a</foo:foo>" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:input];
    XCTAssertNotNil(doc, "");

    STXMLNamespace * const foo = doc.rootElement.namespace;
    XCTAssertEqualObjects(foo.href, @"http://xmlns.chikachow.org/foo");
}

- (void)testXPath1 {
    NSData * const input = [@"<a><b/><c><d>e</d></c><f/></a>" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:input];
    XCTAssertNotNil(doc, "");

    STXPathResult * const result = [doc resultByEvaluatingXPathExpression:@"//a/c/d"];
    XCTAssertNotNil(result, @"");

    STXPathNodeSetResult * const nsresult = (STXPathNodeSetResult *)([result isKindOfClass:[STXPathNodeSetResult class]] ? result : nil);
    XCTAssertNotNil(nsresult, @"");

    STXMLNode * const resultNode = nsresult.nodes.firstObject;
    XCTAssertEqualObjects(resultNode.content, @"e", @"");
}
- (void)testXPath2 {
    NSData * const input = [@"<foo:foo xmlns:foo=\"http://xmlns.chikachow.org/foo\">a</foo:foo>" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    STXMLDocument * const doc = [[STXMLDocument alloc] initWithData:input];
    XCTAssertNotNil(doc, "");

    STXPathResult * const result = [doc resultByEvaluatingXPathExpression:@"/foo:foo" namespaces:@{ @"foo": @"http://xmlns.chikachow.org/foo" }];
    XCTAssertNotNil(result, @"");

    STXPathNodeSetResult * const nsresult = (STXPathNodeSetResult *)([result isKindOfClass:[STXPathNodeSetResult class]] ? result : nil);
    XCTAssertNotNil(nsresult, @"");

    STXMLNode * const resultNode = nsresult.nodes.firstObject;
    XCTAssertEqualObjects(resultNode.content, @"a", @"");
}

@end
