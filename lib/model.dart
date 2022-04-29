// 采集结果
class CollectResult {
  CollectResult({
    this.imageCropBase64 = '',
    this.imageSrcBase64 = '',
    this.error = '',
  });

  factory CollectResult.fromMap(Map<String, dynamic> map) => CollectResult(
      imageCropBase64: map['imageCropBase64'] as String? ?? '',
      imageSrcBase64: map['imageSrcBase64'] as String? ?? '',
      error: map['error'] as String? ?? '');

  /// 抠图加密字符串
  late String imageCropBase64;

  /// 原图加密字符串
  late String imageSrcBase64;
  late String error;
}
