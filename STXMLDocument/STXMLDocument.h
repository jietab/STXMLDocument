//  Copyright (c) 2014 Scott Talbot. All rights reserved.

#import <Foundation/Foundation.h>


@class STXMLDocument;
@class STXMLNode;
@class STXMLElement;


@interface STXMLDocument : NSObject
- (id)initWithData:(NSData *)data;
- (id)initWithData:(NSData *)data error:(NSError * __autoreleasing *)error;
- (id)initWithData:(NSData *)data baseURL:(NSURL *)baseURL;
- (id)initWithData:(NSData *)data baseURL:(NSURL *)baseURL error:(NSError * __autoreleasing *)error;
@property (nonatomic,copy,readonly) STXMLElement *rootElement;
@end


typedef NS_ENUM(NSUInteger, STXMLNodeType) {
    STXMLElementTypeELEMENT = 1,
    STXMLElementTypeATTRIBUTE = 2,
    STXMLElementTypeTEXT = 3,
    STXMLElementTypeSECTION = 4,
    STXMLElementTypeENTITYREF = 5,
    STXMLElementTypeENTITY = 6,
    STXMLElementTypePI = 7,
    STXMLElementTypeCOMMENT = 8,
    STXMLElementTypeDOCUMENT = 9,
    STXMLElementTypeDOCUMENTTYPE = 10,
    STXMLElementTypeDOCUMENTFRAG = 11,
    STXMLElementTypeNOTATION = 12,
    STXMLElementTypeHTMLDOCUMENT = 13,
    STXMLElementTypeDTD = 14,
    STXMLElementTypeELEMENTDECL = 15,
    STXMLElementTypeATTRIBUTEDECL = 16,
    STXMLElementTypeENTITYDECL = 17,
    STXMLElementTypeNAMESPACEDECL = 18,
    STXMLElementTypeXINCLUDESTART = 19,
    STXMLElementTypeXINCLUDEEND = 20,
    STXMLElementTypeDOCBDOCUMENT = 21,
};

typedef BOOL(^STXMLNodePredicate)(STXMLNode *node, BOOL *stop);

extern STXMLNodePredicate STXMLNodeHasName(NSString *name);

@interface STXMLNode : NSObject
@property (nonatomic,assign,readonly) STXMLNodeType type;
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
