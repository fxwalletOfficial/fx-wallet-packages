class AleoUtils {
  static checkPrivateKey(String privateKeyRaw) {
    // check privatekey is valid
    if (!privateKeyRaw.startsWith('APrivateKey1')) {
      throw Exception('Invalid private key prefix');
    }
    final reg = RegExp(r'^[a-zA-Z0-9]{47}$');
    if (!reg.hasMatch(privateKeyRaw.substring(12))) {
      throw Exception('Invalid private key length');
    }
  }

  static checkViewKey(String viewKeyRaw) {
    if (!viewKeyRaw.startsWith('AViewKey1')) {
      throw Exception('Invalid view key prefix');
    }
    final reg = RegExp(r'^[a-zA-Z0-9]{44}$');
    if (!reg.hasMatch(viewKeyRaw.substring(9))) {
      throw Exception('Invalid view key length');
    }
  }

  static checkRecord(String record) {
    if (!record.startsWith('record1')) {
      throw Exception('Invalid record prefix');
    }
  }
}
