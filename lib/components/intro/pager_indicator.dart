import 'dart:ui';

import 'package:flutter/material.dart';
import 'pages.dart';

const BUBBLE_WIDHT = 55.0;

class PagerIndicator extends StatelessWidget {
  const PagerIndicator({
    required this.viewModel,
    Key? key,
  }) : super(key: key);
  final PagerIndicatorViewModel viewModel;


  @override
  Widget build(BuildContext context) {
    List<PageBubble> bubbles = [];
    for (var i = 0; i < viewModel.pages.length; ++i) {
      final page = viewModel.pages[i];

      double percentActive;

      if (i == viewModel.activeIndex) {
        percentActive = 1.0 - viewModel.slidePercent;
      } else if (i == viewModel.activeIndex - 1 && viewModel.slideDirection == SlideDirection.leftToRight) {
        percentActive = viewModel.slidePercent;
      } else if (i == viewModel.activeIndex + 1 && viewModel.slideDirection == SlideDirection.rightToLeft) {
        percentActive = viewModel.slidePercent;
      } else {
        percentActive = 0.0;
      }

      bool isHollow = i > viewModel.activeIndex || (i == viewModel.activeIndex && viewModel.slideDirection == SlideDirection.leftToRight);

      bubbles.add(
        PageBubble(
          viewModel: PageBubbleViewModel(
            page.icon,
            page.color,
            isHollow,
            percentActive,
          ),
        ),
      );
    }

    final baseTranslation = ((viewModel.pages.length * BUBBLE_WIDHT) / 2) - (BUBBLE_WIDHT / 2);
    double translation = baseTranslation - (viewModel.activeIndex * BUBBLE_WIDHT);

    if (viewModel.slideDirection == SlideDirection.leftToRight) {
      translation += BUBBLE_WIDHT * viewModel.slidePercent;
    } else if (viewModel.slideDirection == SlideDirection.rightToLeft) {
      translation -= BUBBLE_WIDHT * viewModel.slidePercent;
    }

    return Column(
      children: <Widget>[
        const Spacer(),
        Transform(
          transform: Matrix4.translationValues(translation / 2.0, 0.0, 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: bubbles,
          ),
        ),
        const SizedBox(height: 20,)
      ],
    );
  }
}

enum SlideDirection {
  leftToRight,
  rightToLeft,
  none,
}

class PagerIndicatorViewModel {
  PagerIndicatorViewModel(this.pages, this.activeIndex, this.slideDirection, this.slidePercent);
  final List<PageViewModel> pages;
  final int activeIndex;
  final SlideDirection slideDirection;
  final double slidePercent;
}

class PageBubble extends StatelessWidget {
  const PageBubble({
    required this.viewModel,
    Key? key,
  }) : super(key: key);
  final PageBubbleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: BUBBLE_WIDHT,
      height: BUBBLE_WIDHT + 10.0,
      child: Center(
        child: Container(
          width: lerpDouble(20.0, 45.0, viewModel.activePercent),
          height: lerpDouble(20.0, 45.0, viewModel.activePercent),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: viewModel.isHollow
                ? const Color(0x88FFFFFF).withAlpha(0x88 * viewModel.activePercent.round())
                : const Color(0x88FFFFFF),
            border: Border.all(
              color: viewModel.isHollow
                  ? const Color(0x88FFFFFF).withAlpha((0x88 * (1.0 - viewModel.activePercent)).round())
                  : Colors.transparent,
              width: 3.0,
            ),
          ),
          child: Opacity(
            child: Icon(viewModel.icon, color: viewModel.color,),
            opacity: viewModel.activePercent,
          ),
        ),
      ),
    );
  }
}

class PageBubbleViewModel {
  final IconData icon;
  final Color color;
  final bool isHollow;
  final double activePercent;

  PageBubbleViewModel(
    this.icon,
    this.color,
    this.isHollow,
    this.activePercent,
  );
}
