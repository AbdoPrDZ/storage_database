class StorageCache<T> {
  T data, expiredData;
  Future<T> Function<T>() source;
  Function() onLoad, onExpire;
  Duration expireDuration;

  StorageCache({
    required this.data,
    required this.expiredData,
    required this.source,
    required this.onLoad,
    required this.onExpire,
    required this.expireDuration,
  }) {
    loadData();
  }

  bool hasData = false;

  loadData() async {
    data = await source();
    hasData = true;
    onLoad();
    initExpire();
  }

  initExpire() => Future.delayed(expireDuration).then((value) {
        expireData();
      });

  expireData() {
    data = expiredData;
    hasData = false;
  }

  Future<T> getData() async {
    if (!hasData) await loadData();
    return data;
  }
}
