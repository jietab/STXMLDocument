//  Copyright (c) 2014 Scott Talbot. All rights reserved.

import Foundation
import XCTest


class STXMLDocumentTests: XCTestCase {

    func testSimpleInstantiation1() {
        var error: NSError?
        let input = " ".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let doc = STXMLDocument(data: input, error: &error)
        XCTAssertNil(doc, "")
        XCTAssertNotNil(error!, "");
        XCTAssertEqual(error!.code, 0x10004, "");
    }
    func testSimpleInstantiation2() {
        let input = "".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let doc = STXMLDocument(data: input)
        XCTAssertNil(doc, "");
    }
    func testSimpleInstantiation3() {
        let input = "<foo/>".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let doc = STXMLDocument(data: input)
        XCTAssertNotNil(doc, "");
    }

    func testRootName1() {
        let input = "<foo/>".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let doc = STXMLDocument(data: input)
        XCTAssertNotNil(doc, "");
        let root: STXMLElement = doc.rootElement;
        XCTAssertNotNil(root, "");
        XCTAssertEqualObjects(root.name, "foo", "");
    }
    func testRootName2() {
        let input = "<foo:foo xmlns:foo=\"http://xmlns.chikachow.org/foo\"/>".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let doc = STXMLDocument(data: input)
        XCTAssertNotNil(doc, "");
        let root: STXMLElement = doc.rootElement;
        XCTAssertNotNil(root, "");
        XCTAssertEqualObjects(root.name, "foo", "");
    }

    func testRootContent1() {
        let input = "<foo>bar</foo>".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let doc = STXMLDocument(data: input)
        XCTAssertNotNil(doc, "");
        let root: STXMLElement = doc.rootElement;
        XCTAssertNotNil(root, "");
        XCTAssertEqualObjects(root.content, "bar", "");
    }

    func testRootContent2() {
        let input = "<?qux quux=\"quuux\"?><!--bar--><foo/>".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let doc = STXMLDocument(data: input)
        XCTAssertNotNil(doc, "");
        let root: STXMLElement = doc.rootElement;
        XCTAssertNotNil(root, "");
        XCTAssertEqualObjects(root.content, "", "");

        let pi: STXMLNode = doc.children[0] as STXMLNode;
        XCTAssertNotNil(pi, "");
        XCTAssertEqual(pi.type, STXMLNodeType.PI, "");
        XCTAssertEqualObjects(pi.content, "quux=\"quuux\"", "");

        let comment: STXMLNode = doc.children[1] as STXMLNode;
        XCTAssertNotNil(comment, "");
        XCTAssertEqual(comment.type, STXMLNodeType.COMMENT, "");
        XCTAssertEqualObjects(comment.content, "bar", "");
    }

    func testChildrenPassingTest1() {
        let input = "<foo><a>.</a><b/><c>,</c></foo>".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let doc = STXMLDocument(data: input)
        XCTAssertNotNil(doc, "");
        let root: STXMLElement = doc.rootElement;
        XCTAssertNotNil(root, "");
        let childrenPassingTest = root.childrenPassingTest { (node: STXMLNode!, stop: CMutablePointer<ObjCBool>) -> Bool in
            switch node.name! {
            case "a":
                return true
            case "c":
                return true
            default:
                return false
            }
        }
        XCTAssertEqual(childrenPassingTest.count, 2, "");

        XCTAssertEqualObjects((childrenPassingTest[0] as STXMLNode).name, "a", "");
        XCTAssertEqualObjects((childrenPassingTest[0] as STXMLNode).content, ".", "");
        XCTAssertEqualObjects((childrenPassingTest[1] as STXMLNode).name, "c", "");
        XCTAssertEqualObjects((childrenPassingTest[1] as STXMLNode).content, ",", "");
    }

    func testChildrenPassingTest2() {
        let input = "<foo><a/><b/><a/></foo>".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let doc = STXMLDocument(data: input)
        XCTAssertNotNil(doc, "");
        let root: STXMLElement = doc.rootElement;
        XCTAssertNotNil(root, "");
        let childrenPassingTest = root.childrenPassingTest { (node: STXMLNode!, stop: CMutablePointer<ObjCBool>) -> Bool in return node.name == "a" }
        XCTAssertEqual(childrenPassingTest.count, 2, "");
    }

    func testAttributes1() {
        let input = "<foo a=\"b\"/>" .dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let doc = STXMLDocument(data: input)
        XCTAssertNotNil(doc, "");
        let root: STXMLElement = doc.rootElement;
        XCTAssertNotNil(root, "");
        let attributesPassingTest = root.attributesPassingTest { (node: STXMLNode!, stop: CMutablePointer<ObjCBool>) -> Bool in return node.name == "a" }
        XCTAssertEqual(attributesPassingTest.count, 1, "");
        let attribute = attributesPassingTest[0] as STXMLNode
        XCTAssertEqualObjects(attribute.name, "a", "");
        XCTAssertEqualObjects(attribute.content, "b", "");
    }

    func testXPath1() {
        let input = "<a><b/><c><d>e</d></c><f/></a>" .dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let doc = STXMLDocument(data: input)
        XCTAssertNotNil(doc, "");
        let result = doc.resultByEvaluatingXPathExpression("//a/c/d") as STXPathNodeSetResult
        XCTAssertNotNil(result, "");
        let resultNode = result.nodes[0] as STXMLNode
        let resultNodeContent = resultNode.content
        XCTAssertEqualObjects(resultNodeContent, "e", "");
    }

}
