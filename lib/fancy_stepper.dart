import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class FancyStepper extends StatefulWidget {
  const FancyStepper({
    super.key,
    this.initStep = 0,
    this.minStep = 0,
    this.maxStep = 100,
    required this.width,
    required this.height,
    this.color = Colors.deepPurple,
    this.radius = 20,
    this.onChanged,
    this.arrowsSize = 35.0,
    this.style,
  })  : assert(maxStep > minStep),
        assert(initStep <= maxStep && initStep >= minStep);
  final int initStep;
  final double width;
  final double height;
  final Color color;
  final double radius;
  final Function(int step)? onChanged;
  final int maxStep;
  final int minStep;
  final double arrowsSize;
  final TextStyle? style;

  @override
  State<FancyStepper> createState() => _FancyStepperState();
}

class _FancyStepperState extends State<FancyStepper>
    with SingleTickerProviderStateMixin {
  final style = const TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  final rowKey = GlobalKey();

  late AnimationController controller;
  late Animation<Offset> animation;

  // states
  late int _current;
  Offset _dragOffset = Offset.zero;
  Offset _clickOffset = Offset.zero;
  Timer? timer;
  Duration timerDuration = const Duration(milliseconds: 400);
  Duration prevTimerDuration = const Duration(milliseconds: 400);

  // set, get
  set current(int v) {
    if (_current == v) return;
    setState(() {
      _current = v;
    });
    widget.onChanged?.call(_current);
  }

  set dragOffset(Offset v) {
    if (v == _dragOffset) return;
    setState(() {
      _dragOffset = v;
    });
  }

  set clickOffset(Offset v) {
    if (v == _clickOffset) return;
    _clickOffset = v;
  }

  @override
  void initState() {
    super.initState();
    _current = widget.initStep;
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    animation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(controller);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      key: rowKey,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Backward icon.
        Icon(
          Icons.arrow_back_ios_new_rounded,
          size: widget.arrowsSize,
          color: widget.color.withOpacity(.15),
        ),
        const SizedBox(width: 10),

        // Stepper.
        GestureDetector(
          onHorizontalDragStart: onHorizontalDragStart,
          onHorizontalDragUpdate: onHorizontalDragUpdate,
          onHorizontalDragEnd: onHorizontalDragEnd,
          child: AnimatedSlide(
            curve:
                _dragOffset == Offset.zero ? Curves.easeOutBack : Curves.ease,
            duration: Duration(
              milliseconds: _dragOffset == Offset.zero ? 300 : 100,
            ),
            offset: Offset(_dragOffset.dx / widget.width, 0),
            child: Container(
              width: widget.width,
              height: widget.height,
              alignment: Alignment.center,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.radius),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 15),
                    color: widget.color.withOpacity(.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Prev number.
                  AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: animation.value,
                        child: child,
                      );
                    },
                    child: Transform.translate(
                      offset: Offset(-widget.width, 0),
                      child:
                          Text("${_current - 1}", style: widget.style ?? style),
                    ),
                  ),

                  // Current number.
                  AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: animation.value,
                        child: child,
                      );
                    },
                    child: Text("$_current", style: widget.style ?? style),
                  ),

                  // Next number.
                  AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: animation.value,
                        child: child,
                      );
                    },
                    child: Transform.translate(
                      offset: Offset(widget.width, 0),
                      child:
                          Text("${_current + 1}", style: widget.style ?? style),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Forward icon.
        const SizedBox(width: 10),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: widget.arrowsSize,
          color: widget.color.withOpacity(.15),
        ),
      ],
    );
  }

  void forward(Duration speed) {
    if (controller.isAnimating || _current + 1 > widget.maxStep) return;

    controller.duration = speed;
    animation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-widget.width, 0),
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));

    controller.forward().then((_) {
      controller.reset();
      current = _current + 1;
    });
  }

  void backward(Duration speed) {
    if (controller.isAnimating || _current - 1 < widget.minStep) return;

    controller.duration = speed;
    animation = Tween(
      begin: Offset.zero,
      end: Offset(widget.width, 0),
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));

    controller.forward().then((_) {
      controller.reset();
      current = _current - 1;
    });
  }

  void onHorizontalDragStart(DragStartDetails details) {
    clickOffset = details.localPosition;
  }

  void onHorizontalDragEnd(DragEndDetails detials) {
    if (timer?.isActive ?? false) {
      if (_dragOffset.dx > 0) {
        forward(const Duration(milliseconds: 500));
      } else {
        backward(const Duration(milliseconds: 500));
      }
    }

    dragOffset = Offset.zero;
    clickOffset = Offset.zero;
    resetTimer();
    resetDurations();
  }

  void onHorizontalDragUpdate(DragUpdateDetails details) {
    final size = (rowKey.currentContext!.findRenderObject() as RenderBox).size;
    final allowDistance = (size.width - widget.width) / 2;
    bool inRange =
        (details.localPosition.dx - _clickOffset.dx >= -allowDistance) &&
            (details.localPosition.dx - _clickOffset.dx <= allowDistance);
    if (inRange) {
      dragOffset = Offset(details.localPosition.dx - _clickOffset.dx, 0);
    } else {
      if (_dragOffset.dx > 0) {
        startTimer(forward);
      } else {
        startTimer(backward);
      }
    }
  }

  void startTimer(Function(Duration) callback) {
    if (prevTimerDuration != timerDuration) {
      resetTimer();
      prevTimerDuration = timerDuration;
    }
    timer ??= Timer.periodic(timerDuration, (timer) {
      if (timer.tick % 2 == 0) {
        timerDuration = Duration(
          milliseconds: max(prevTimerDuration.inMilliseconds - 100, 50),
        );
      }
      callback.call(timerDuration);
    });
  }

  void resetTimer() {
    if (timer == null) return;
    timer?.cancel();
    timer = null;
  }

  void resetDurations() {
    timerDuration = const Duration(milliseconds: 400);
    prevTimerDuration = const Duration(milliseconds: 400);
  }

  @override
  void dispose() {
    controller.dispose();
    timer?.cancel();
    super.dispose();
  }
}
