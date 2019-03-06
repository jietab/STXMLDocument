//  Copyright (c) 2014 Scott Talbot. All rights reserved.

#import "STXMLBuilder.h"

#import <libxml/tree.h>
#import <libxml/xmlsave.h>


@class STXMLBuilderDocument;
@class STXMLBuilderNamespace;
@class STXMLBuilderAttribute;
@class STXMLBuilderNode;
@class STXMLBuilderElement;


@interface STXMLBuilderDocument : NSObject<STXMLBuilderDocument> {
@package
    xmlDocPtr _doc;
    NSMapTable *_instantiatedNamespacesByNsPtr;
    NSMutableArray *_children;
}
- (STXMLBuilderNamespace *)uniquedNamespaceForNsPtr:(xmlNsPtr)nodePtr;
@end
@interface STXMLBuilderNamespace : NSObject<STXMLBuilderNamespace> {
    @package
    STXMLBuilderDocument * __weak _doc;
    xmlNsPtr _ns;
}
- (instancetype)initWithDocument:(STXMLBuilderDocument *)document ns:(xmlNsPtr)ns;
@end
@interface STXMLBuilderNode : NSObject<STXMLBuilderNode> {
    @package
    STXMLBuilderDocument * __weak _doc;
    xmlNodePtr _node;
    NSMutableArray *_attributes;
    NSMutableArray *_children;
}
- (instancetype)initWithDocument:(STXMLBuilderDocument *)document node:(xmlNodePtr)node;
@end
@interface STXMLBuilderAttribute : STXMLBuilderNode<STXMLBuilderAttribute>
- (instancetype)initWithDocument:(STXMLBuilderDocument *)document node:(xmlAttrPtr)node;
@end
@interface STXMLBuilderElement : STXMLBuilderNode<STXMLBuilderElement>
- (instancetype)initWithDocument:(STXMLBuilderDocument *)document node:(xmlNodePtr)node;
@end


@implementation STXMLBuilder

+ (id<STXMLBuilderDocument>)document {
    return [[STXMLBuilderDocument alloc] init];
}

@end


@implementation STXMLBuilderNamespace
- (instancetype)init {
    return [self initWithDocument:nil ns:NULL];
}
- (instancetype)initWithDocument:(STXMLBuilderDocument *)document ns:(xmlNsPtr)ns {
    if ((self = [super init])) {
        _doc = document;
        _ns = ns;
    }
    return self;
}
- (void)dealloc {
//    xmlFreeNs(_ns), _ns = NULL;
}
@end


@implementation STXMLBuilderNode
- (instancetype)init {
    return [self initWithDocument:nil node:nil];
}
- (instancetype)initWithDocument:(STXMLBuilderDocument *)document node:(xmlNodePtr)node {
    NSParameterAssert(document);
    NSParameterAssert(node);
    if ((self = [super init])) {
        _doc = document;
        _node = node;
        _attributes = [[NSMutableArray alloc] init];
        _children = [[NSMutableArray alloc] init];
    }
    return self;
}
//- (void)dealloc {
//    if (_doc) {
//    } else {
////        xmlFreeNode(_node), _node = NULL;
//    }
//}


- (id<STXMLBuilderNamespace>)addNamespaceWithPrefix:(NSString *)prefix_ href:(NSString *)href_ {
    xmlChar const * const prefix = (xmlChar const *)[prefix_ cStringUsingEncoding:NSUTF8StringEncoding];
    xmlChar const * const href = (xmlChar const *)[href_ cStringUsingEncoding:NSUTF8StringEncoding];
    xmlNsPtr const ns = xmlNewNs(_node, href, prefix);
    xmlAddChild(_node, (xmlNodePtr)ns);
    return [_doc uniquedNamespaceForNsPtr:ns];
}
- (id<STXMLBuilderNamespace>)namespaceForPrefix:(NSString *)prefix_ {
    STXMLBuilderDocument * const doc = _doc;
    xmlChar const * const prefix = (xmlChar const *)[prefix_ cStringUsingEncoding:NSUTF8StringEncoding];
    xmlNsPtr const ns = xmlSearchNs(doc->_doc, _node, prefix);
    if (!ns) {
        return nil;
    }
    return [doc uniquedNamespaceForNsPtr:ns];
}
- (id<STXMLBuilderNamespace>)namespaceForHref:(NSString *)href_ {
    STXMLBuilderDocument * const doc = _doc;
    xmlChar const * const href = (xmlChar const *)[href_ cStringUsingEncoding:NSUTF8StringEncoding];
    xmlNsPtr const ns = xmlSearchNsByHref(doc->_doc, _node, href);
    if (!ns) {
        return nil;
    }
    return [doc uniquedNamespaceForNsPtr:ns];
}

- (id<STXMLBuilderAttribute>)addAttributeWithNamespace:(STXMLBuilderNamespace *)namespace name:(NSString *)name_ value:(NSString *)value_ {
    xmlNsPtr const ns = namespace ? namespace->_ns : NULL;
    xmlChar const * const name = (xmlChar const *)[name_ cStringUsingEncoding:NSUTF8StringEncoding];
    xmlChar const * const value = (xmlChar const *)[value_ cStringUsingEncoding:NSUTF8StringEncoding];
    xmlAttrPtr const node = xmlNewNsProp(_node, ns, name, value);
    xmlAddChild(_node, (xmlNodePtr)node);
    STXMLBuilderAttribute * const attribute = [[STXMLBuilderAttribute alloc] initWithDocument:_doc node:node];
    [_attributes addObject:attribute];
    return attribute;
}
- (id<STXMLBuilderElement>)addChildElementWithNamespace:(STXMLBuilderNamespace *)namespace name:(NSString *)name_ {
    xmlNsPtr const ns = namespace ? namespace->_ns : NULL;
    xmlChar const * const name = (xmlChar const *)[name_ cStringUsingEncoding:NSUTF8StringEncoding];
    xmlNodePtr const node = xmlNewNode(ns, name);
    xmlAddChild(_node, node);
    STXMLBuilderElement * const child = [[STXMLBuilderElement alloc] initWithDocument:_doc node:node];
//    if (ns) {
//        xmlNsPtr const nodens = xmlNewNs(node, ns->href, ns->prefix);
//        xmlSetNs(node, nodens);
//        STXMLBuilderNamespace * const namespace = [[STXMLBuilderNamespace alloc] initWithDocument:self ns:ns];
//        [child->_namespaces addObject:namespace];
//    }
    [_children addObject:child];
    return child;
}
- (id<STXMLBuilderElement>)addChildElementWithNamespacePrefix:(NSString *)prefix_ href:(NSString *)href_ name:(NSString *)name_ {
    STXMLBuilderDocument * const doc = _doc;
    xmlChar const * const prefix = (xmlChar const *)[prefix_ cStringUsingEncoding:NSUTF8StringEncoding];
    xmlChar const * const href = (xmlChar const *)[href_ cStringUsingEncoding:NSUTF8StringEncoding];
    xmlChar const * const name = (xmlChar const *)[name_ cStringUsingEncoding:NSUTF8StringEncoding];
    xmlNodePtr const node = xmlNewNode(NULL, name);
    xmlNsPtr const ns = xmlNewNs(node, href, prefix);
    xmlAddChild(_node, node);
    xmlSetNs(node, ns);
    STXMLBuilderElement * const child = [[STXMLBuilderElement alloc] initWithDocument:doc node:node];
    [_children addObject:child];
    return child;
}
- (id<STXMLBuilderNode>)addTextNodeWithContent:(NSString *)content_ {
    xmlChar const * const content = (xmlChar const *)[content_ cStringUsingEncoding:NSUTF8StringEncoding];
    xmlNodePtr const node = xmlNewText(content);
    xmlAddChild(_node, node);
    STXMLBuilderNode * const child = [[STXMLBuilderNode alloc] initWithDocument:_doc node:node];
    [_children addObject:child];
    return child;
}
@end

@implementation STXMLBuilderAttribute
- (instancetype)initWithDocument:(STXMLBuilderDocument *)document node:(xmlAttrPtr)node {
    return [super initWithDocument:document node:(xmlNodePtr)node];
}
@end

@implementation STXMLBuilderElement
- (instancetype)initWithDocument:(STXMLBuilderDocument *)document node:(xmlNodePtr)node {
    return [super initWithDocument:document node:node];
}
- (id<STXMLBuilderNamespace>)addNamespaceWithPrefix:(NSString *)prefix href:(NSString *)href {
    return [super addNamespaceWithPrefix:prefix href:href];
}
- (id<STXMLBuilderNamespace>)namespaceForPrefix:(NSString *)prefix {
    return [super namespaceForPrefix:prefix];
}
- (id<STXMLBuilderNamespace>)namespaceForHref:(NSString *)href {
    return [super namespaceForHref:href];
}
- (id<STXMLBuilderAttribute>)addAttributeWithNamespace:(id<STXMLBuilderNamespace>)ns name:(NSString *)name value:(NSString *)value {
    return [super addAttributeWithNamespace:ns name:name value:value];
}
- (id<STXMLBuilderElement>)addChildElementWithNamespace:(id<STXMLBuilderNamespace>)ns name:(NSString *)name {
    return [super addChildElementWithNamespace:ns name:name];
}
- (id<STXMLBuilderElement>)addChildElementWithNamespacePrefix:(NSString *)prefix href:(NSString *)href name:(NSString *)name {
    return [super addChildElementWithNamespacePrefix:prefix href:href name:name];
}
- (id<STXMLBuilderNode>)addTextNodeWithContent:(NSString *)content {
    return [super addTextNodeWithContent:content];
}
@end



@implementation STXMLBuilderDocument

- (instancetype)init {
    if ((self = [super init])) {
        _doc = xmlNewDoc((unsigned char const *)"1.1");
        _instantiatedNamespacesByNsPtr = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsIntegerPersonality|NSPointerFunctionsOpaqueMemory valueOptions:NSPointerFunctionsObjectPersonality|NSPointerFunctionsWeakMemory capacity:0];
        _children = [[NSMutableArray alloc] init];
    }
    return self;
}
- (void)dealloc {
    xmlFreeDoc(_doc);
    _doc = NULL;
}


- (STXMLBuilderNamespace *)uniquedNamespaceForNsPtr:(xmlNsPtr)nsPtr {
    if (!nsPtr) {
        return nil;
    }

    __unsafe_unretained id const key = (__bridge id)(void *)(nsPtr);
    STXMLBuilderNamespace *node = [_instantiatedNamespacesByNsPtr objectForKey:key];
    if (!node) {
        node = [[STXMLBuilderNamespace alloc] initWithDocument:self ns:nsPtr];
        if (node) {
            [_instantiatedNamespacesByNsPtr setObject:node forKey:key];
        }
    }
    return node;
}

- (id<STXMLBuilderNamespace>)addNamespaceWithPrefix:(NSString *)prefix_ href:(NSString *)href_ {
    xmlChar const * const prefix = (xmlChar const *)[prefix_ cStringUsingEncoding:NSUTF8StringEncoding];
    xmlChar const * const href = (xmlChar const *)[href_ cStringUsingEncoding:NSUTF8StringEncoding];
    xmlNsPtr const ns = xmlNewNs(NULL, href, prefix);
    xmlAddChild((xmlNodePtr)_doc, (xmlNodePtr)ns);
    return [self uniquedNamespaceForNsPtr:ns];
}

- (id<STXMLBuilderElement>)addChildElementWithNamespace:(STXMLBuilderNamespace *)namespace name:(NSString *)name_ {
    xmlNsPtr const ns = namespace ? namespace->_ns : NULL;
    xmlChar const * const name = (xmlChar const *)[name_ cStringUsingEncoding:NSUTF8StringEncoding];
    xmlNodePtr const node = xmlNewDocRawNode(_doc, ns, name, NULL);
    xmlAddChild((xmlNodePtr)_doc, node);
    STXMLBuilderElement * const child = [[STXMLBuilderElement alloc] initWithDocument:self node:node];
    if (ns) {
        xmlNsPtr const nodens = xmlNewNs(node, ns->href, ns->prefix);
        xmlSetNs(node, nodens);
    }
    [_children addObject:child];
    return child;
}

- (id<STXMLBuilderElement>)addChildElementWithNamespacePrefix:(NSString *)prefix_ href:(NSString *)href_ name:(NSString *)name_ {
    xmlChar const * const prefix = (xmlChar const *)[prefix_ cStringUsingEncoding:NSUTF8StringEncoding];
    xmlChar const * const href = (xmlChar const *)[href_ cStringUsingEncoding:NSUTF8StringEncoding];
    xmlChar const * const name = (xmlChar const *)[name_ cStringUsingEncoding:NSUTF8StringEncoding];
    xmlNodePtr const node = xmlNewDocRawNode(_doc, NULL, name, NULL);
    xmlNsPtr const ns = xmlNewNs(node, href, prefix);
    xmlAddChild((xmlNodePtr)_doc, node);
    xmlSetNs(node, ns);
    STXMLBuilderElement * const child = [[STXMLBuilderElement alloc] initWithDocument:self node:node];
    [_children addObject:child];
    return child;
}

- (NSData *)dataUsingEncoding:(NSStringEncoding)encoding {
    return [self dataUsingEncoding:encoding options:0];
}
- (NSData *)dataUsingEncoding:(NSStringEncoding)encoding options:(STXMLBuilderWritingOptions)options {
    switch (encoding) {
        case NSUTF8StringEncoding:
            break;
        default:
            return nil;
    }

    xmlBufferPtr buf = xmlBufferCreate();
    xmlSaveCtxtPtr ctx = xmlSaveToBuffer(buf, "UTF-8", options);
    xmlSaveDoc(ctx, _doc);
    xmlSaveFlush(ctx);
    NSData * const data = [[NSData alloc] initWithBytes:xmlBufferContent(buf) length:(NSUInteger)xmlBufferLength(buf)];
    xmlSaveClose(ctx);
    ctx = NULL;
    xmlBufferFree(buf);
    buf = NULL;
    return data;
}

@end
