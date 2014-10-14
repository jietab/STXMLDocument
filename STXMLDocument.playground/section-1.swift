// Playground - noun: a place where people can play

import Foundation

import STXMLDocument


let bd = STXMLBuilder.document()

let r = bd.addChildElementWithNamespacePrefix("foo", href: "http://chikachow.org/foo", name: "a")
r.addTextNodeWithContent("bar");

let z = bd.dataUsingEncoding(NSUTF8StringEncoding, options: STXMLBuilderWritingOptions.Formatted)
let sz = NSString(data: z, encoding: NSUTF8StringEncoding)
