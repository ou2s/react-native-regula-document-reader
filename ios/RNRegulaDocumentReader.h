
#if __has_include(<React/RCTBridgeModule.h>)
#import <React/RCTBridgeModule.h>
#import <React/RCTImageStoreManager.h>
#else
#import "RCTBridgeModule.h"
#import "RCTImageStoreManager.h"
#endif

#ifndef DEBUG
#import <DocumentReader/DocumentReader-Swift.h>
#endif

@interface RNRegulaDocumentReader : NSObject <RCTBridgeModule>

#ifndef DEBUG
@property (strong, nonatomic) DocReader *docReader;
#endif

@end
