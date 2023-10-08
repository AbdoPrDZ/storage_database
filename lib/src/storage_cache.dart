class StorageCache<T> {
  T? data;
  final T? expiredData;
  final Future<T?> Function() source;
  final Function()? onLoad, onExpire;
  final Duration expireDuration;

  StorageCache({
    required this.data,
    this.expiredData,
    required this.source,
    this.onLoad,
    this.onExpire,
    this.expireDuration = const Duration(seconds: 2),
  });

  bool hasData = false;

  loadData() async {
    data = await source();
    hasData = true;
    onLoad?.call();
    initExpire();
  }

  initExpire() => Future.delayed(expireDuration).then((value) => expireData());

  expireData() {
    data = expiredData;
    hasData = false;
    onExpire?.call();
  }

  Future<T?> getData() async {
    if (!hasData) await loadData();
    return data;
  }
}
