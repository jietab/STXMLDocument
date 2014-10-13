//  Copyright (c) 2014 Scott Talbot. All rights reserved.

import Foundation
import XCTest


class STXMLBuilderTests: XCTestCase {

    func testSimple1() {
        let d = STXMLBuilder.document()
        let r = d.addChildElementWithNamespacePrefix("a", href: "http://chikachow.org/a", name: "a")
    }

}
