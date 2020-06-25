import 'package:flutter/material.dart';

const FONT_SIZE_TITLE = 22.0;
const FONT_SIZE_BODY = 16.0;

class OnboardingPage extends StatefulWidget {
  final PageViewModel viewModel;
  final double percentVisible;

  OnboardingPage({this.viewModel, this.percentVisible = 1.0});

  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation _animation;

  @override
  void initState() {
    _animationController = AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    _animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.ease
    ));
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(OnboardingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewModel != oldWidget.viewModel) {
      _animationController.reset();
      if (widget.percentVisible == 1.0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _animationController.forward();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: widget.viewModel.color,
      padding: EdgeInsets.all(40.0),
      child: Opacity(
        opacity: widget.percentVisible,
        child: OrientationBuilder(builder: (context, orientation) {
          return Flex(
            direction: orientation == Orientation.portrait ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Transform(
                    transform: Matrix4.translationValues(0.0, 50.0 * (1.0 - widget.percentVisible), 0.0),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 25.0),
                      // child: viewModel.heroTag == null ? viewModel.hero : Hero(tag: viewModel.heroTag, child: viewModel.hero),
                      child: AnimatedBuilder(
                        animation: _animationController, builder: (context, child) {
                          return Transform.scale(
                            scale: _animation.value,
                            child: widget.viewModel.heroTag == null ? widget.viewModel.hero : Hero(tag: widget.viewModel.heroTag, child: widget.viewModel.hero),
                          );
                        }
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: orientation == Orientation.portrait ? EdgeInsets.zero : EdgeInsets.only(left: 50.0, top: 50.0),
                child: Column(crossAxisAlignment: orientation == Orientation.portrait ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: <Widget>[
                  Transform(
                    transform: Matrix4.translationValues(0.0, 30.0 * (1.0 - widget.percentVisible), 0.0),
                    child: Padding(
                      padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                      child: Text(
                        widget.viewModel.title ?? '',
                        style: TextStyle(
                          color: widget.viewModel.titleColor ?? Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: FONT_SIZE_TITLE,
                        ),
                      ),
                    ),
                  ),
                  Transform(
                    transform: Matrix4.translationValues(0.0, 30.0 * (1.0 - widget.percentVisible), 0.0),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 75.0),
                      child: Text(
                        widget.viewModel.body ?? '',
                        textAlign: orientation == Orientation.portrait ? TextAlign.center :  TextAlign.start,
                        style: TextStyle(
                          color: widget.viewModel.bodyColor ?? Colors.white,
                          fontSize: FONT_SIZE_BODY,
                        ),
                      ),
                    ),
                  ),
                ],),
              ),
            ],
          );
        },),
      ),
    );
  }
}

class PageViewModel {
  final Color color;
  final Widget hero;
  final String heroTag;
  final String title;
  final String body;
  final Color titleColor;
  final Color bodyColor;
  final IconData icon;

  PageViewModel({
    this.color,
    this.hero,
    this.heroTag,
    this.title,
    this.body,
    this.titleColor,
    this.bodyColor,
    this.icon,
  });

  @override
  bool operator ==(Object other) => identical(this, other) ||
    (other is PageViewModel && runtimeType == other.runtimeType && other.title == title);

}