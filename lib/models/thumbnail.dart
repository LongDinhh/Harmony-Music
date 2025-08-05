class Thumbnail {
  Thumbnail(this._url);
  final String _url;
  String sizeWith(int size) => (_url.contains("-rj"))
      ? "${_url.split("=")[0]}=w$size-h$size-l90-rj"
      : (_url.contains("=s"))
          ? "${_url.split("=s")[0]}=s$size"
          : (_url.contains("i.yti") && size >= 600)
              ? url.replaceFirst("sddefault", "maxresdefault")
              : url;
  String get url => _url;
  String get high => sizeWith(400); //450
  String get medium => sizeWith(250); //350
  String get low => sizeWith(150);
  String get extraHigh => sizeWith(600); //150
}
