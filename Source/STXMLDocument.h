//  Copyright (c) 2014 Scott Talbot. All rights reserved.

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, STXMLNodeType) {
    STXMLNodeTypeELEMENT = 1,
    STXMLNodeTypeATTRIBUTE = 2,
    STXMLNodeTypeTEXT = 3,
    STXMLNodeTypeSECTION = 4,
    STXMLNodeTypeENTITYREF = 5,
    STXMLNodeTypeENTITY = 6,
    STXMLNodeTypePI = 7,
    STXMLNodeTypeCOMMENT = 8,
    STXMLNodeTypeDOCUMENT = 9,
    STXMLNodeTypeDOCUMENTTYPE = 10,
    STXMLNodeTypeDOCUMENTFRAG = 11,
    STXMLNodeTypeNOTATION = 12,
    STXMLNodeTypeHTMLDOCUMENT = 13,
    STXMLNodeTypeDTD = 14,
    STXMLNodeTypeELEMENTDECL = 15,
    STXMLNodeTypeATTRIBUTEDECL = 16,
    STXMLNodeTypeENTITYDECL = 17,
    STXMLNodeTypeNAMESPACEDECL = 18,
    STXMLNodeTypeXINCLUDESTART = 19,
    STXMLNodeTypeXINCLUDEEND = 20,
    STXMLNodeTypeDOCBDOCUMENT = 21,
};

@class STXMLDocument;
@class STXMLNode;
@class STXMLElement;
@class STXMLNamespace;
@class STXPathResult;

typedef BOOL(^STXMLNodePredicate)(STXMLNode *node, BOOL *stop);

extern STXMLNodePredicate STXMLNodeHasName(NSString *name);


@interface STXMLDocument : NSObject
- (id)initWithData:(NSData *)data;
- (id)initWithData:(NSData *)data error:(NSError * __autoreleasing *)error;
- (id)initWithData:(NSData *)data baseURL:(NSURL *)baseURL;
- (id)initWithData:(NSData *)data baseURL:(NSURL *)baseURL error:(NSError * __autoreleasing *)error;
@property (nonatomic,copy,readonly) STXMLElement *rootElement;
@property (nonatomic,copy,readonly) NSArray *children;
- (STXPathResult *)resultByEvaluatingXPathExpression:(NSString *)xpath;
- (STXPathResult *)resultByEvaluatingXPathExpression:(NSString *)xpath namespaces:(NSDictionary *)namespaces;
- (STXPathResult *)resultByEvaluatingXPathExpression:(NSString *)xpath namespaces:(NSDictionary *)namespaces error:(NSError * __autoreleasing *)error;
@end


@interface STXMLNode : NSObject
@property (nonatomic,assign,readonly) STXMLNodeType type;
@property (nonatomic,strong,readonly) STXMLNamespace *namespace;
@property (nonatomic,copy,readonly) NSString *name;
@property (nonatomic,copy,readonly) NSArray *children;
- (NSArray *)childrenPassingTest:(STXMLNodePredicate)predicate;
@property (nonatomic,copy,readonly) NSArray *attributes;
- (NSArray *)attributesPassingTest:(STXMLNodePredicate)predicate;
@property (nonatomic,copy,readonly) NSString *content;
@end

@interface STXMLElement : STXMLNode
@end

@interface STXMLAttribute : STXMLNode
@end

@interface STXMLNamespace : NSObject
@property (nonatomic,copy,readonly) NSString *href;
@end


@interface STXPathResult : NSObject
@end

@interface STXPathNodeSetResult : STXPathResult
@property (nonatomic,copy,readonly) NSArray *nodes;
@end


#import <STXMLDocument/STXMLBuilder.h>
