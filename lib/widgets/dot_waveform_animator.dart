import 'package:flutter/material.dart';

class DotWaveformAnimator extends StatefulWidget {
  final bool isVisible;
  final Stream<double>? soundLevelStream;

  const DotWaveformAnimator({
    Key? key,
    required this.isVisible,
    this.soundLevelStream,
  }) : super(key: key);

  @override
  _DotWaveformAnimatorState createState() => _DotWaveformAnimatorState();
}

class _DotWaveformAnimatorState extends State<DotWaveformAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  double _currentDiameter = 100.0;
  final double _minDiameter = 100.0;
  final double _maxDiameter = 300.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _updateDiameter(double value) {
    if (!widget.isVisible) {
      setState(() {
        _currentDiameter = _minDiameter;
      });
      return;
    }

    // More responsive scaling with cubic effect
    double scaleFactor = 5.0;
    double normalizedValue = value.clamp(0.0, 1.0);
    double cubicValue = normalizedValue * normalizedValue * normalizedValue;
    double newDiameter = _minDiameter +
        (cubicValue * (_maxDiameter - _minDiameter) * scaleFactor);

    setState(() {
      _currentDiameter = newDiameter.clamp(_minDiameter, _maxDiameter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: widget.soundLevelStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _updateDiameter(snapshot.data!);
        }

        return Center(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseValue = _pulseController.value * 0.2;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: _currentDiameter,
                height: _currentDiameter,
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: widget.isVisible
                      ? Colors.blue.withOpacity(0.6 + pulseValue)
                      : Colors.grey.withOpacity(0.3),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3 + pulseValue),
                      blurRadius: _currentDiameter * 0.2,
                      spreadRadius: _currentDiameter * 0.1,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.8 + pulseValue),
                    width: 2.0,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
