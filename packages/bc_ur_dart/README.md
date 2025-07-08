# bc_ur_dart
A dart plugin for Uniform Resources(URs) decode/encode. URs are URI-encoded CBOR structures developed by Blockchain Commons.


## Getting Started
### Install
```
dependencies:
  bc_ur_dart: ^0.1.15
```

### Usage
```dart
// Decode UR string
final ur = UR.decode('ur:bytes/hdeymejtswhhylkepmykhhtsytsnoyoyaxaedsuttydmmhhpktpmsrjtgwdpfnsboxgwlbaawzuefywkdplrsrjynbvygabwjldapfcsdwkbrkch');

// Encode to String.
ur.encode();

// Encode to fragment string.
ur.next();

// Read fragment UR.
final ur = UR();
ur.read(fragment);
```