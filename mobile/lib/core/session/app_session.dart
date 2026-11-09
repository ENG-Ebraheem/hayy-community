class AppSession {
  // ._ ههذا يعني ان ال كونسترمتر private ونفعله على شان نطبق ال singltone
  AppSession._();

  static final AppSession instance = AppSession._();

  String? demoUid;
  String? demoToken;

  bool get isDemo => demoUid != null && demoToken != null;

  void startDemo({required String uid}) {
    demoUid = uid;
    demoToken = 'dev-token-$uid';
  }

  void clear() {
    demoUid = null;
    demoToken = null;
  }
}
