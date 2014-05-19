//  Copyright (c) 2014 Scott Talbot. All rights reserved.

#import "STXMLDocument.h"

#include <libxml/parser.h>


@interface STXMLNode ()
- (id)initWithDocument:(STXMLDocument *)doc nodePtr:(xmlNodePtr)nodePtr;
@end


@implementation STXMLDocument {
@private
    xmlParserCtxt _pctx;
    xmlDocPtr _doc;
    STXMLElement *_rootElement;
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
        xmlInitParserCtxt(&_pctx);

        NSString * const baseURLString = baseURL.absoluteString;
        const char * const baseURLUTF8String = [baseURLString cStringUsingEncoding:NSUTF8StringEncoding];
        xmlDocPtr const doc = _doc = xmlCtxtReadMemory(&_pctx, bytes, (int)length, baseURLUTF8String, NULL, XML_PARSE_NOENT|XML_PARSE_NOBLANKS|XML_PARSE_COMPACT);
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
    }
    return self;
}

- (void)dealloc {
    xmlClearParserCtxt(&_pctx);
    xmlFreeDoc(_doc);
}


- (STXMLElement *)rootElement {
    if (!_rootElement) {
        xmlNodePtr const rootNodePtr = xmlDocGetRootElement(_doc);
        _rootElement = [[STXMLElement alloc] initWithDocument:self nodePtr:rootNodePtr];
    }
    return _rootElement;
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
    xmlFreeNode(_node);
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
            switch (child->type) {
                case XML_ELEMENT_NODE: {
                    STXMLElement * const childNode = [[STXMLElement alloc] initWithDocument:doc nodePtr:child];
                    [children addObject:childNode];
                } break;
                default: {
                    STXMLNode * const childNode = [[STXMLNode alloc] initWithDocument:doc nodePtr:child];
                    [children addObject:childNode];
                } break;
            }
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
        xmlNodePtr const node = _node;

        NSMutableArray * const attributes = [[NSMutableArray alloc] initWithCapacity:0];

        for (xmlAttrPtr attribute = node->properties; attribute; attribute = attribute->next) {
            STXMLAttribute * const attributeNode = [[STXMLAttribute alloc] initWithDocument:_doc nodePtr:(xmlNodePtr)attribute];
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
