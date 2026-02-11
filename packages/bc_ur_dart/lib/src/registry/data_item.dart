import 'package:cbor/cbor.dart';

cborValueSetTags(CborValue value, List<int> tags){
  if(value is Map<CborValue, CborValue>){
    return CborMap(value as Map<CborValue, CborValue>, tags: tags);
  }
  if(value is CborBytes){
    return CborBytes(value.bytes, tags: tags);
  }
  if(value is CborString){
    return CborString(value.toString(), tags: tags);
  }
}
