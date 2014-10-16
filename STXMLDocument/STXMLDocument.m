//  Copyright (c) 2014 Scott Talbot. All rights reserved.

#import "STXMLDocument.h"

#include <libxml/parser.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>


@interface STXMLDocument ()
- (STXMLNode *)uniquedNodeForNodePtr:(xmlNodePtr)nodePtr;
- (STXMLNamespace *)uniquedNamespaceForNsPtr:(xmlNsPtr)nsPtr;
@end

@interface STXMLNode ()
- (id)initWithDocument:(STXMLDocument *)doc nodePtr:(xmlNodePtr)nodePtr;
@end

@interface STXMLNamespace ()
- (id)initWithDocument:(STXMLDocument *)doc nsPtr:(xmlNsPtr)nsPtr;
@end

@interface STXPathResult ()
- (id)initWithDocument:(STXMLDocument *)doc xpathContextPtr:(xmlXPathContextPtr)xpathContextPtr objectPtr:(xmlXPathObjectPtr)xpathObjectPtr;
@end


@implementation STXMLDocument {
@private
    xmlParserCtxt _pctx;
    xmlDocPtr _doc;
    NSString *_name;
    NSArray *_children;
    STXMLElement *_rootElement;
    NSMapTable *_instantiatedNodesByNodePtr;
    NSMapTable *_instantiatedNamespacesByNsPtr;
}

- (id)init {
    return [self initWithData:nil baseURL:nil error:NULL];
}
- (id)initWithData:(NSData *)data {
    return [self initWithData:data baseURL:nil error:NULL];
}
- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error {
    return [self initWithData:data baseURL:nil error:error];
}
- (id)initWithData:(NSData *)data baseURL:(NSURL *)baseURL {
    return [self initWithData:data baseURL:baseURL error:NULL];
}
- (id)initWithData:(NSData *)data baseURL:(NSURL *)baseURL error:(NSError * __autoreleasing *)error {
    char const * const bytes = data.bytes;
    size_t const length = data.length;
    if (length == 0) {
        if (error) {
            NSInteger const errorCode = ((XML_FROM_PARSER << 16) | (XML_ERR_DOCUMENT_EMPTY));
            *error = [[NSError alloc] initWithDomain:@"STXML" code:errorCode userInfo:nil];
        }
        return nil;
    }

    if ((self = [super init])) {
        _instantiatedNodesByNodePtr = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsIntegerPersonality|NSPointerFunctionsOpaqueMemory valueOptions:NSPointerFunctionsObjectPersonality|NSPointerFunctionsWeakMemory capacity:0];
        _instantiatedNamespacesByNsPtr = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsIntegerPersonality|NSPointerFunctionsOpaqueMemory valueOptions:NSPointerFunctionsObjectPersonality|NSPointerFunctionsWeakMemory capacity:0];

        xmlInitParserCtxt(&_pctx);

        NSString * const baseURLString = baseURL.absoluteString;
        char const * const baseURLUTF8String = (char *)[baseURLString cStringUsingEncoding:NSUTF8StringEncoding];
        xmlDocPtr const doc = _doc = xmlCtxtReadMemory(&_pctx, bytes, (int)length, baseURLUTF8String, NULL, XML_PARSE_NOENT|XML_PARSE_NOERROR|XML_PARSE_NOBLANKS|XML_PARSE_NONET|XML_PARSE_COMPACT);
        if (!doc) {
            if (error) {
                xmlErrorPtr const xmlerr = xmlCtxtGetLastError(&_pctx);
                if (xmlerr) {
                    NSInteger const errorCode = ((xmlerr->domain << 16) | (xmlerr->code));
                    *error = [[NSError alloc] initWithDomain:@"STXML" code:errorCode userInfo:nil];
                }
            }
            return nil;
        }

        {
            unsigned long const count = xmlChildElementCount((xmlNodePtr)doc);
            NSMutableArray * const children = [[NSMutableArray alloc] initWithCapacity:count];

            for (xmlNodePtr child = doc->children; child; child = child->next) {
                STXMLNode * const childNode = [self uniquedNodeForNodePtr:child];
                [children addObject:childNode];
            }
            _children = children.copy;
        }

        {
            xmlNodePtr const rootNodePtr = xmlDocGetRootElement(_doc);
            _rootElement = (STXMLElement *)[self uniquedNodeForNodePtr:rootNodePtr];
        }
    }
    return self;
}

- (void)dealloc {
    xmlFreeDoc(_doc);
    xmlClearParserCtxt(&_pctx);
}


- (STXMLNode *)uniquedNodeForNodePtr:(xmlNodePtr)nodePtr {
    if (!nodePtr) {
        return nil;
    }

    __unsafe_unretained id const key = (__bridge id)(void *)(nodePtr);
    STXMLNode *node = [_instantiatedNodesByNodePtr objectForKey:key];
    if (!node) {
        switch (nodePtr->type) {
            case XML_ELEMENT_NODE: {
                node = [[STXMLElement alloc] initWithDocument:self nodePtr:nodePtr];
            } break;
            case XML_ATTRIBUTE_NODE: {
                node = [[STXMLAttribute alloc] initWithDocument:self nodePtr:nodePtr];
            } break;
            case XML_TEXT_NODE:
            case XML_CDATA_SECTION_NODE:
            case XML_ENTITY_REF_NODE:
            case XML_ENTITY_NODE:
            case XML_PI_NODE:
            case XML_COMMENT_NODE:
            case XML_DOCUMENT_NODE:
            case XML_DOCUMENT_TYPE_NODE:
            case XML_DOCUMENT_FRAG_NODE:
            case XML_NOTATION_NODE:
            case XML_HTML_DOCUMENT_NODE:
            case XML_DTD_NODE:
            case XML_ELEMENT_DECL:
            case XML_ATTRIBUTE_DECL:
            case XML_ENTITY_DECL:
            case XML_NAMESPACE_DECL:
            case XML_XINCLUDE_START:
            case XML_XINCLUDE_END:
#ifdef LIBXML_DOCB_ENABLED
            case XML_DOCB_DOCUMENT_NODE:
#endif
                break;
        }
        if (!node) {
            node = [[STXMLNode alloc] initWithDocument:self nodePtr:nodePtr];
        }
        if (node) {
            [_instantiatedNodesByNodePtr setObject:node forKey:key];
        }
    }
    return node;
}

- (STXMLNamespace *)uniquedNamespaceForNsPtr:(xmlNsPtr)nsPtr {
    if (!nsPtr) {
        return nil;
    }

    __unsafe_unretained id const key = (__bridge id)(void *)(nsPtr);
    STXMLNamespace *namespace = [_instantiatedNamespacesByNsPtr objectForKey:key];
    if (!namespace) {
        namespace = [[STXMLNamespace alloc] initWithDocument:self nsPtr:nsPtr];
        if (namespace) {
            [_instantiatedNamespacesByNsPtr setObject:namespace forKey:key];
        }
    }
    return namespace;
}

- (STXPathResult *)resultByEvaluatingXPathExpression:(NSString *)xpath {
    return [self resultByEvaluatingXPathExpression:xpath namespaces:nil error:NULL];
}
- (STXPathResult *)resultByEvaluatingXPathExpression:(NSString *)xpath namespaces:(NSDictionary *)namespaces {
    return [self resultByEvaluatingXPathExpression:xpath namespaces:namespaces error:NULL];
}
- (STXPathResult *)resultByEvaluatingXPathExpression:(NSString *)xpath namespaces:(NSDictionary *)namespaces error:(NSError * __autoreleasing *)error {
    if (xpath.length == 0) {
        return nil;
    }

    xmlChar const * const str = (xmlChar const *)[xpath cStringUsingEncoding:NSUTF8StringEncoding];
    xmlDocPtr const doc = _doc;
    xmlXPathContextPtr const ctx = xmlXPathNewContext(doc);
    for (NSString *prefix in namespaces) {
        NSString * const namespace = namespaces[prefix];
        if ([prefix isKindOfClass:[NSString class]] && [namespace isKindOfClass:[NSString class]]) {
            xmlChar const * const prefix_str = (xmlChar const *)[prefix cStringUsingEncoding:NSUTF8StringEncoding];
            xmlChar const * const namespace_str = (xmlChar const *)[namespace cStringUsingEncoding:NSUTF8StringEncoding];
            if (xmlXPathRegisterNs(ctx, prefix_str, namespace_str)) {
                xmlErrorPtr const xmlerr = xmlCtxtGetLastError(&_pctx);
                if (xmlerr) {
                    NSInteger const errorCode = ((xmlerr->domain << 16) | (xmlerr->code));
                    if (error) {
                        *error = [[NSError alloc] initWithDomain:@"STXML" code:errorCode userInfo:nil];
                    }
                }
                return nil;
            }
        } else {
            return nil;
        }
    }
    xmlXPathObjectPtr const xpathObject = xmlXPathEval(str, ctx);
    if (!xpathObject) {
        xmlErrorPtr const xmlerr = xmlCtxtGetLastError(&_pctx);
        if (xmlerr) {
            NSInteger const errorCode = ((xmlerr->domain << 16) | (xmlerr->code));
            if (error) {
                *error = [[NSError alloc] initWithDomain:@"STXML" code:errorCode userInfo:nil];
            }
        }
        return nil;
    }

    Class klass = nil;
    switch (xpathObject->type) {
        case XPATH_NODESET:
            klass = [STXPathNodeSetResult class];
            break;
        default:
            break;
    }
    if (klass == nil) {
        klass = [STXPathResult class];
    }
    return [[klass alloc] initWithDocument:self xpathContextPtr:ctx objectPtr:xpathObject];
}

@end


STXMLNodePredicate STXMLNodeHasName(NSString *name) {
    return ^(STXMLNode *node, BOOL *stop){
        return [node.name isEqualToString:name];
    };
}

@implementation STXMLNode {
@protected
    STXMLDocument *_doc;
    xmlNodePtr _node;
    STXMLNamespace *_namespace;
    NSString *_name;
    NSArray *_children;
    NSArray *_attributes;
    NSString *_content;
}

- (id)init {
    return [self initWithDocument:nil nodePtr:NULL];
}
- (id)initWithDocument:(STXMLDocument *)doc nodePtr:(xmlNodePtr)nodePtr {
    NSParameterAssert(doc);
    NSParameterAssert(nodePtr);
    if ((self = [super init])) {
        _doc = doc;
        _node = nodePtr;
    }
    return self;
}

- (void)dealloc {
//    xmlFreeDoc() on the root takes care of this
//    xmlFreeNode(_node);
}

- (STXMLNodeType)type {
    return (STXMLNodeType)_node->type;
}

- (STXMLNamespace *)namespace {
    if (!_namespace) {
        STXMLDocument * const doc = _doc;
        xmlNodePtr const node = _node;
        xmlNsPtr const ns = node->ns;
        if (ns) {
            _namespace = [doc uniquedNamespaceForNsPtr:ns];
        }
    }
    return _namespace;
}

- (NSString *)name {
    if (!_name) {
        xmlNodePtr const node = _node;

        xmlChar const * const name = node->name;
        int const length = xmlStrlen(name);
        _name = [[NSString alloc] initWithBytesNoCopy:(void *)name length:(NSUInteger)length encoding:NSUTF8StringEncoding freeWhenDone:NO];
    }
    return _name;
}


- (NSArray *)children {
    if (!_children) {
        STXMLDocument * const doc = _doc;
        xmlNodePtr const node = _node;

        unsigned long const count = xmlChildElementCount(node);
        NSMutableArray * const children = [[NSMutableArray alloc] initWithCapacity:count];

        for (xmlNodePtr child = node->children; child; child = child->next) {
            STXMLNode * const childNode = [doc uniquedNodeForNodePtr:child];
            [children addObject:childNode];
        }

        _children = children.copy;
    }
    return _children;
}

- (NSArray *)childrenPassingTest:(STXMLNodePredicate)predicate {
    if (!predicate) {
        return @[];
    }

    NSArray * const children = self.children;
    NSIndexSet * const indexes = [children indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return predicate(obj, stop);
    }];
    return [children objectsAtIndexes:indexes];
}


- (NSArray *)attributes {
    if (!_attributes) {
        STXMLDocument * const doc = _doc;
        xmlNodePtr const node = _node;

        NSMutableArray * const attributes = [[NSMutableArray alloc] initWithCapacity:0];

        for (xmlAttrPtr attribute = node->properties; attribute; attribute = attribute->next) {
            STXMLNode * const attributeNode = [doc uniquedNodeForNodePtr:(xmlNodePtr)attribute];
            [attributes addObject:attributeNode];
        }

        _attributes = attributes.copy;

    }
    return _attributes;
}

- (NSArray *)attributesPassingTest:(STXMLNodePredicate)predicate {
    if (!predicate) {
        return @[];
    }

    NSArray * const attributes = self.attributes;
    NSIndexSet * const indexes = [attributes indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return predicate(obj, stop);
    }];
    return [attributes objectsAtIndexes:indexes];

}


- (NSString *)content {
    if (!_content) {
        xmlNodePtr const node = _node;
        xmlChar const * const content = xmlNodeGetContent(node);
        int const length = xmlStrlen(content);
        _content = [[NSString alloc] initWithBytesNoCopy:(void *)content length:(NSUInteger)length encoding:NSUTF8StringEncoding freeWhenDone:YES];
    }
    return _content;
}

@end


@implementation STXMLElement
@end


@implementation STXMLAttribute
@end


@implementation STXMLNamespace {
@protected
    STXMLDocument *_doc;
    xmlNsPtr _ns;
    NSString *_href;
}

- (id)init {
    return [self initWithDocument:nil nsPtr:NULL];
}

- (id)initWithDocument:(STXMLDocument *)doc nsPtr:(xmlNsPtr)nsPtr {
    NSParameterAssert(doc);
    NSParameterAssert(nsPtr);
    if ((self = [super init])) {
        _doc = doc;
        _ns = nsPtr;
    }
    return self;
}

- (NSString *)href {
    if (!_href) {
        xmlNsPtr const ns = _ns;
        xmlChar const * const href = ns->href;
        if (href) {
            int const length = xmlStrlen(href);
            _href = [[NSString alloc] initWithBytes:(void *)href length:(NSUInteger)length encoding:NSUTF8StringEncoding];
        }
    }
    return _href;
}

@end


@implementation STXPathResult {
@protected
    STXMLDocument *_doc;
    xmlXPathContextPtr _xpathContext;
    xmlXPathObjectPtr _xpathObject;
}

- (id)init {
    return [self initWithDocument:nil xpathContextPtr:NULL objectPtr:NULL];
}

- (id)initWithDocument:(STXMLDocument *)doc xpathContextPtr:(xmlXPathContextPtr)xpathContextPtr objectPtr:(xmlXPathObjectPtr)xpathObjectPtr {
    NSParameterAssert(doc);
    NSParameterAssert(xpathObjectPtr);
    if ((self = [super init])) {
        _doc = doc;
        _xpathContext = xpathContextPtr;
        _xpathObject = xpathObjectPtr;
    }
    return self;
}

- (void)dealloc {
    xmlXPathFreeObject(_xpathObject);
    xmlXPathFreeContext(_xpathContext);
}

@end


@implementation STXPathNodeSetResult {
@protected
    NSArray *_nodes;
}

- (NSArray *)nodes {
    if (!_nodes) {
        STXMLDocument * const doc = _doc;
        xmlXPathObjectPtr const xpathObject = _xpathObject;
        xmlNodeSetPtr const nodeset = xpathObject->nodesetval;
        if (!nodeset) {
            return nil;
        }

        NSMutableArray * const nodes = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)nodeset->nodeNr];

        for (int i = 0; i < nodeset->nodeNr; ++i) {
            xmlNodePtr const node = nodeset->nodeTab[i];
            STXMLNode * const n = [doc uniquedNodeForNodePtr:node];
            [nodes addObject:n];
            (void)n;
        }

        _nodes = nodes.copy;
    }
    return _nodes;
}

@end
