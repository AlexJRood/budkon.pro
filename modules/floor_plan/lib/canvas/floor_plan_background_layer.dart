part of 'floor_plan_canvas.dart';

class _FloorPlanBackgroundLayer extends StatefulWidget {
  final FloorPlanBackgroundImage? backgroundImage;

  const _FloorPlanBackgroundLayer({
    required this.backgroundImage,
  });

  @override
  State<_FloorPlanBackgroundLayer> createState() =>
      _FloorPlanBackgroundLayerState();
}

class _FloorPlanBackgroundLayerState extends State<_FloorPlanBackgroundLayer> {
  ui.Image? _decodedImage;
  String? _decodedId;

  @override
  void initState() {
    super.initState();
    _decodeIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _FloorPlanBackgroundLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _decodeIfNeeded();
  }

  Future<void> _decodeIfNeeded() async {
    final background = widget.backgroundImage;

    if (background == null) {
      if (_decodedImage != null || _decodedId != null) {
        setState(() {
          _decodedImage = null;
          _decodedId = null;
        });
      }

      return;
    }

    if (_decodedId == background.id && _decodedImage != null) {
      return;
    }

    final codec = await ui.instantiateImageCodec(background.bytes);
    final frame = await codec.getNextFrame();

    if (!mounted) return;

    setState(() {
      _decodedImage = frame.image;
      _decodedId = background.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.backgroundImage;
    final image = _decodedImage;

    if (background == null || image == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: background.x,
      top: background.y,
      width: background.width,
      height: background.height,
      child: IgnorePointer(
        ignoring: background.locked,
        child: Opacity(
          opacity: background.opacity.clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: background.rotationDeg * math.pi / 180.0,
            child: RawImage(
              image: image,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}