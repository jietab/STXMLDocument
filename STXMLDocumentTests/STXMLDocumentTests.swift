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
        XCTAssertEqual(root.name!, "foo", "");
    }
    func testRootName2() {
        let input = "<foo:foo xmlns:foo=\"http://xmlns.chikachow.org/foo\"/>".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let doc = STXMLDocument(data: input)
        XCTAssertNotNil(doc, "");
        let root: STXMLElement = doc.rootElement;
        XCTAssertNotNil(root, "");
        XCTAssertEqual(root.name!, "foo", "");
    }

    func testRootContent1() {
        let input = "<foo>bar</foo>".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let doc = STXMLDocument(data: input)
        XCTAssertNotNil(doc, "");
        let root: STXMLElement = doc.rootElement;
        XCTAssertNotNil(root, "");
        XCTAssertEqual(root.content!, "bar", "");
    }

    func testRootContent2() {
        let input = "<?qux quux=\"quuux\"?><!--bar--><foo/>".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let doc = STXMLDocument(data: input)
        XCTAssertNotNil(doc, "");
        let root: STXMLElement = doc.rootElement;
        XCTAssertNotNil(root, "");
        XCTAssertEqual(root.content!, "", "");

        let pi: STXMLNode = doc.children[0] as STXMLNode;
        XCTAssertNotNil(pi, "");
        XCTAssertEqual(pi.type, STXMLNodeType.PI, "");
        XCTAssertEqual(pi.content!, "quux=\"quuux\"", "");

        let comment: STXMLNode = doc.children[1] as STXMLNode;
        XCTAssertNotNil(comment, "");
        XCTAssertEqual(comment.type, STXMLNodeType.COMMENT, "");
        XCTAssertEqual(comment.content!, "bar", "");
    }

    func testChildrenPassingTest1() {
        let input = "<foo><a>.</a><b/><c>,</c></foo>".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let doc = STXMLDocument(data: input)
        XCTAssertNotNil(doc, "");
        let root: STXMLElement = doc.rootElement;
        XCTAssertNotNil(root, "");

        let childrenPassingTest = root.childrenPassingTest { (node: STXMLNode!, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
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

        XCTAssertEqual((childrenPassingTest[0] as STXMLNode).name!, "a", "");
        XCTAssertEqual((childrenPassingTest[0] as STXMLNode).content!, ".", "");
        XCTAssertEqual((childrenPassingTest[1] as STXMLNode).name!, "c", "");
        XCTAssertEqual((childrenPassingTest[1] as STXMLNode).content!, ",", "");
    }

    func testChildrenPassingTest2() {
        let input = "<foo><a/><b/><a/></foo>".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let doc = STXMLDocument(data: input)
        XCTAssertNotNil(doc, "");
        let root: STXMLElement = doc.rootElement;
        XCTAssertNotNil(root, "");
        let childrenPassingTest = root.childrenPassingTest { (node: STXMLNode!, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in return node.name == "a" }
        XCTAssertEqual(childrenPassingTest.count, 2, "");
    }

    func testAttributes1() {
        let input = "<foo a=\"b\"/>" .dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let doc = STXMLDocument(data: input)
        XCTAssertNotNil(doc, "");
        let root: STXMLElement = doc.rootElement;
        XCTAssertNotNil(root, "");

        let attributesPassingTest = root.attributesPassingTest { (node: STXMLNode!, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in return node.name == "a" } as [STXMLAttribute]!
        XCTAssertEqual(attributesPassingTest.count, 1, "");

        let attribute = attributesPassingTest[0] as STXMLNode
        XCTAssertEqual(attribute.name!, "a", "");
        XCTAssertEqual(attribute.content!, "b", "");

        let attributesPassingTest2: Array<STXMLAttribute> = root.attributes.filter { (o: AnyObject) -> Bool in
            let attribute = o as? STXMLAttribute
            return attribute?.name == "a"
        } as [STXMLAttribute]
        XCTAssert(attributesPassingTest! == attributesPassingTest2)
    }

    func testXPath1() {
        let input = "<a><b/><c><d>e</d></c><f/></a>" .dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let doc = STXMLDocument(data: input)
        XCTAssertNotNil(doc, "");
        if let result = doc.resultByEvaluatingXPathExpression("//a/c/d") as? STXPathNodeSetResult {
            let resultNode = result.nodes[0] as STXMLNode
            let resultNodeContent = resultNode.content
            XCTAssertEqual(resultNodeContent!, "e", "");
        } else {
            XCTAssert(false)
        }
    }

}