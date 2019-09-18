@import UIKit;
#import "RNRegulaDocumentReader.h"

@implementation RNRegulaDocumentReader

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

// We check if we build on Release or Debug because Regula does not compile on Simulator
#ifndef DEBUG


RCT_EXPORT_METHOD(prepareDatabase:(NSDictionary*) options callback:(RCTResponseSenderBlock)callback)
{
    NSString *dbID = options[@"dbID"];
    ProcessParams *params = [[ProcessParams alloc] init];
    self.docReader = [[DocReader alloc] initWithProcessParams:params];
    
    [self.docReader prepareDatabaseWithDatabaseID:dbID progressHandler:^(NSProgress * _Nonnull progress) {
        // self.initializationLabel.text = [NSString stringWithFormat:@"%.1f", progress.fractionCompleted * 100];
    } completion:^(BOOL successful, NSString * _Nullable error) {
        if (successful) {
            callback(@[[NSNull null], [NSNull null]]);
        } else {
            callback(@[error, [NSNull null]]);
        }
    }];
}

RCT_EXPORT_METHOD(initialize:(RCTResponseSenderBlock)callback)
{
    NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"regula.license" ofType:nil];
    NSData *licenseData = [NSData dataWithContentsOfFile:dataPath];
    
    ProcessParams *params = [[ProcessParams alloc] init];
    self.docReader = [[DocReader alloc] initWithProcessParams:params];
    
    [self.docReader initilizeReaderWithLicense:licenseData completion:^(BOOL successful, NSString * _Nullable error ) {
        if (successful) {
            NSLog(@"SUCCESS");
            callback(@[[NSNull null], [NSNull null]]);
        } else {
            NSLog(@"NO SUCCESS");

            callback(@[error, [NSNull null]]);
        }
    }];
}

- (void )handleImage:(UIImage *)image imageName:(NSString *)imageName withBlock:(void (^)(id field, id value))setField {
    NSLog(@"before store Image %@", imageName);
    NSLog(@"w=%f / h=%f", image.size.width, image.size.height);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = UIImagePNGRepresentation(image);
        NSLog(@"after store Image - data = %@", @(data.length));
        
        [self->_bridge.imageStoreManager storeImageData:data withBlock:^(NSString *imageTag) {
            setField(imageName, imageTag);
        }];
    });

}


- (NSMutableDictionary *)handleTextFieldResults:(DocumentReaderResults *)result {
    
    // use fast getValue method
    NSString *address = [result getTextFieldValueByTypeWithFieldType:FieldTypeFt_Address];
//    NSLog(@"address = %@", address);
    
    NSMutableDictionary *scannedFields = [NSMutableDictionary new];
    for (DocumentReaderTextField *textField in result.textResult.fields) {
        NSString *value = [result getTextFieldValueByTypeWithFieldType:textField.fieldType lcid:textField.lcid];
//        NSLog(@"Field type name: %@, value: %@", textField.fieldName, value);
        scannedFields[textField.fieldName] = value;
    }
    
    return scannedFields;
}

RCT_REMAP_METHOD(scan, scan:(NSDictionary*)opts withResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *currentViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        
        [self.docReader.processParams setValuesForKeysWithDictionary:opts[@"processParams"]];
        [self.docReader.functionality setValuesForKeysWithDictionary:opts[@"functionality"]];
        [self.docReader.customization setValuesForKeysWithDictionary:opts[@"customization"]];
        
        [self.docReader showScanner:currentViewController completion:^(enum DocReaderAction action, DocumentReaderResults * _Nullable result, NSString * _Nullable error) {
            NSLog(@"DocumentReaderAction %ld", (long)action);
            switch (action) {
                case DocReaderActionCancel: {
                    NSLog(@"DocReaderActionCancel");
                    
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Cancelled by user"};
                    return reject(@"canceled", @"Cancelled by user", [NSError errorWithDomain:@"regula-react-native" code:200 userInfo:userInfo]);
                    break;
                }
                    
                case DocReaderActionComplete: {
                    NSLog(@"DocReaderActionComplete");
                    
                    if (result != nil) {
                        NSMutableDictionary *textResults  = [self handleTextFieldResults:result];
                        
                        __block NSMutableDictionary *totalResults = [NSMutableDictionary new];
                        totalResults[@"textFields"] = textResults;
                        __block int togo = 0;
                        void __block (^setField)(id field, id value) = ^(id field, id value)
                        {
                            
                            totalResults[field] = value;
                            togo--;
                            if (togo == 0) {
                                NSLog(@"------ totalResults = %@", totalResults);
                                [self.docReader stopScanner];
                                return resolve(totalResults);
                            }
                        };
                        
                        
                        UIImage *front = [result getGraphicFieldImageByTypeWithFieldType:GraphicFieldTypeGf_DocumentFront source:ResultTypeRawImage];
                        
                        UIImage *back = [result getGraphicFieldImageByTypeWithFieldType:GraphicFieldTypeGf_DocumentRear source:ResultTypeRawImage];
                        
                        UIImage *portrait = [result getGraphicFieldImageByTypeWithFieldType:GraphicFieldTypeGf_Portrait];
                        
                        UIImage *signature = [result getGraphicFieldImageByTypeWithFieldType:GraphicFieldTypeGf_Signature ];
                        
                        if (front != nil) {
                            togo++;
                            [self handleImage:front imageName:@"imageFront" withBlock:setField];
                            
                        }
                        
                        if (back != nil) {
                            togo++;
                            [self handleImage:back imageName:@"imageBack" withBlock:setField];
                        }
                        
                        if (portrait != nil) {
                            togo++;
                            [self handleImage:portrait imageName:@"imagePortrait" withBlock:setField];
                        }
                        
                        if (signature != nil) {
                            togo++;
                            [self handleImage:signature imageName:@"imageSignature" withBlock:setField];
                        }
                    }
                    break;
                }
                    
                case DocReaderActionError: {
                    NSLog(@"DocReaderActionError");
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: error};
                    return reject(@"error", error, [NSError errorWithDomain:@"regula-react-native" code:200 userInfo:userInfo]);
                    break;
                }
                    
                case DocReaderActionProcess: {
                    NSLog(@"DocReaderActionProcess");
                    break;
                }
                    
                case DocReaderActionMorePagesAvailable: {
                    NSLog(@"DocReaderActionMorePagesAvailable");
                    break;
                }
                    
                default: {
                    NSLog(@"default");
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"unknown scanning status"};
                    return reject(@"error", error, [NSError errorWithDomain:@"regula-react-native" code:200 userInfo:userInfo]);
                    break;
                }
            }
        }];
    });
}
#endif

@end
