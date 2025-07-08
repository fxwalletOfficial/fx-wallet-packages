import '../entity/k_line_entity.dart';

class InfoWindowEntity {
  KLineEntity kLineEntity;
  bool isLeft;
  bool _isShow = false;

  InfoWindowEntity(
    this.kLineEntity, {
    this.isLeft = false,
  });

  void show() => _isShow = true;

  bool get isShow => _isShow;
}
