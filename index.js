import {NativeModules} from 'react-native';
import {wrap} from './wrap';

const Scenario = {
   mrz: 'Mrz',
   ocr: 'Ocr',
   barcode: 'Barcode',
   locate: 'Locate',
   docType: 'DocType',
   mrzOrBarcode: 'MrzOrBarcode',
   mrzOrLocate: 'MrzOrLocate',
   mrzAndLocate: 'MrzAndLocate',
   mrzOrOcr: 'MrzOrOcr',
   mrzOrBarcodeOrOcr: 'MrzOrBarcodeOrOcr',
   locateVisual_And_MrzOrOcr: 'LocateVisual_And_MrzOrOcr',
   fullProcess: 'FullProcess',
   id3Rus: 'Id3Rus',
};

let  reader;
let scan;
if (__DEV__) {
   scan = async ({...opts}) => {
      const mockedResults = {
         imageBack: 'rct-image-store://1',
         imageFront: 'rct-image-store://0',
         imagePortrait: 'rct-image-store://2',
         imageSignature: 'rct-image-store://3',
         textFields: {
            Age: 24,
            'Check digit for date of birth': 8,
            'Check digit for document number': 0,
            'Date of birth': '08/12/1985',
            'Date of expiry': '15/10/2032',
            'Date of issue': '16/10/2017',
            'Document #': 171027351252,
            'Document class code': 'ID',
            'Final check digit': 7,
            'Given name': 'FRANCIS',
            'Issuing state': 'France',
            'Issuing state code': 'FRA',
            'MRZ lines':
               'IDFRACABREL<<<<<<<<<<<<<<<<<<<027036\n1710273512520FRANCIS<8512089M7',
            'MRZ lines with correct checksums':
               'IDFRACABREL<<<<<<<<<<<<<<<<<<<027036\n1710273512520FRANCIS<8512089M7',
            'Months to expire': '157',
            'Optional data': '027028',
            'Place of issue': 'PR\\U00c9FECTURE DE L EURE ( 27 )',
            Sex: 'M',
            Surname: 'CABREL',
            'Surname and given names': 'CABREL FRANCIS',
            'Place of birth' : 'Lille'
         },
      };
      return Promise.resolve(mockedResults);
   };
} else {
   reader = wrap(NativeModules.RNRegulaDocumentReader);
   const {initialize, prepareDatabase} = reader;
   scan = async ({...opts}) => {
      await initialize();
      return NativeModules.RNRegulaDocumentReader.scan(opts);
   };
}


export default {
   scan,
   Scenario,
};
