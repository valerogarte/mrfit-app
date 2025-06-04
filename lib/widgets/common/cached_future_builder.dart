import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class CachedFutureBuilder<T> extends StatefulWidget {
  final Future<T> Function() futureBuilder;
  final Widget Function(BuildContext, AsyncSnapshot<T>) builder;
  final List<Object?> keys;

  const CachedFutureBuilder({
    Key? key,
    required this.futureBuilder,
    required this.builder,
    required this.keys,
  }) : super(key: key);

  @override
  State<CachedFutureBuilder<T>> createState() => _CachedFutureBuilderState<T>();
}

class _CachedFutureBuilderState<T> extends State<CachedFutureBuilder<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.futureBuilder();
  }

  @override
  void didUpdateWidget(covariant CachedFutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.keys, oldWidget.keys)) {
      _future = widget.futureBuilder();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: widget.builder,
    );
  }
}
