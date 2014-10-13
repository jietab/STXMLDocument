//  Copyright (c) 2014 Scott Talbot. All rights reserved.

#import <Foundation/Foundation.h>

#import <STXMLDocument/STXMLDocument.h>


@protocol STXMLBuilderNamespace;
@protocol STXMLBuilderDocument;
@protocol STXMLBuilderAttribute;
@protocol STXMLBuilderNode;
@protocol STXMLBuilderElement;


@protocol STXMLBuilderNamespace <NSObject>
@end


typedef NS_OPTIONS(NSInteger, STXMLBuilderWritingOptions) {
    STXMLBuilderWritingFormatted = 1<<0,
    STXMLBuilderWritingOmitDeclaration = 1<<1,
    STXMLBuilderWritingOmitEmptyTags = 1<<2,
    STXMLBuilderWritingFormattedWithNonSignificantWhitespace = 1<<7,
};

@protocol STXMLBuilderDocument <NSObject>
//- (id<STXMLBuilderNamespace>)addNamespaceWithPrefix:(NSString *)prefix href:(NSString *)href;
//- (id<STXMLBuilderNamespace>)namespaceWithPrefix:(NSString *)prefix href:(NSString *)href;
//- (id<STXMLBuilderElement>)addChildElementWithNamespace:(id<STXMLBuilderNamespace>)ns name:(NSString *)name;
- (id<STXMLBuilderElement>)addChildElementWithNamespacePrefix:(NSString *)prefix href:(NSString *)href name:(NSString *)name;
- (NSData *)dataUsingEncoding:(NSStringEncoding)encoding; // only utf8 supported :-)
- (NSData *)dataUsingEncoding:(NSStringEncoding)encoding options:(STXMLBuilderWritingOptions)options; // only utf8 supported :-)
@end

@protocol STXMLBuilderAttribute <NSObject>
@end

@protocol STXMLBuilderNode <NSObject>
@end

@protocol STXMLBuilderElement <NSObject>
- (id<STXMLBuilderNamespace>)addNamespaceWithPrefix:(NSString *)prefix href:(NSString *)href;
- (id<STXMLBuilderNamespace>)namespaceForPrefix:(NSString *)prefix;
- (id<STXMLBuilderNamespace>)namespaceForHref:(NSString *)href;
- (id<STXMLBuilderAttribute>)addAttributeWithNamespace:(id<STXMLBuilderNamespace>)ns name:(NSString *)name value:(NSString *)value;
- (id<STXMLBuilderElement>)addChildElementWithNamespace:(id<STXMLBuilderNamespace>)ns name:(NSString *)name;
- (id<STXMLBuilderElement>)addChildElementWithNamespacePrefix:(NSString *)prefix href:(NSString *)href name:(NSString *)name;
- (id<STXMLBuilderNode>)addTextNodeWithContent:(NSString *)content;
@end


@interface STXMLBuilder : NSObject
+ (id<STXMLBuilderDocument>)document;
@end
