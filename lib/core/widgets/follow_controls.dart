import 'package:flutter/material.dart';
import 'dart:ui';

class FollowControls extends StatefulWidget {
  final bool isFollowing;
  final VoidCallback onToggleFollow;
  final VoidCallback onStopPressed;

  const FollowControls({
    Key? key,
    required this.isFollowing,
    required this.onToggleFollow,
    required this.onStopPressed,
  }) : super(key: key);

  @override
  State<FollowControls> createState() => _FollowControlsState();
}

class _FollowControlsState extends State<FollowControls>
    with TickerProviderStateMixin {
  late AnimationController _buttonController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMainActionButton(),
                // const SizedBox(width: 20),
                // _buildStopButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainActionButton() {
    return Expanded(
      flex: 2,
      child: GestureDetector(
        onTapDown: (_) => _buttonController.forward(),
        onTapUp: (_) => _buttonController.reverse(),
        onTapCancel: () => _buttonController.reverse(),
        onTap: widget.onToggleFollow,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isFollowing
                        ? [
                            const Color(0xFFFF6B35),
                            const Color(0xFFFF8E53),
                          ]
                        : [
                            const Color(0xFF4CAF50),
                            const Color(0xFF66BB6A),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isFollowing 
                          ? const Color(0xFFFF6B35) 
                          : const Color(0xFF4CAF50)).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        widget.isFollowing ? Icons.person_off_rounded : Icons.person_search_rounded,
                        key: ValueKey(widget.isFollowing),
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        widget.isFollowing ? 'DỪNG THEO DÕI' : 'BẮT ĐẦU THEO DÕI',
                        key: ValueKey(widget.isFollowing),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStopButton() {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _buttonController.forward(),
        onTapUp: (_) => _buttonController.reverse(),
        onTapCancel: () => _buttonController.reverse(),
        onTap: widget.onStopPressed,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE53E3E),
                      Color(0xFFFC8181),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE53E3E).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stop_circle_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'DỪNG\nROBOT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}