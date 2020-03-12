import 'package:flutter/material.dart';

const FONT_SIZE_TITLE = 22.0;
const FONT_SIZE_BODY = 16.0;

class Page extends StatelessWidget {
  final PageViewModel viewModel;
  final double percentVisible;

  Page({this.viewModel, this.percentVisible = 1.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: viewModel.color,
      padding: EdgeInsets.all(40.0),
      child: Opacity(
        opacity: percentVisible,
        child: OrientationBuilder(builder: (context, orientation) {
          return Flex(
            direction: orientation == Orientation.portrait ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Transform(
                    transform: Matrix4.translationValues(0.0, 50.0 * (1.0 - percentVisible), 0.0),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 25.0),
                      child: viewModel.heroTag == null ? viewModel.hero : Hero(tag: viewModel.heroTag, child: viewModel.hero),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: orientation == Orientation.portrait ? EdgeInsets.zero : EdgeInsets.only(left: 50.0, top: 50.0),
                child: Column(crossAxisAlignment: orientation == Orientation.portrait ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: <Widget>[
                  Transform(
                    transform: Matrix4.translationValues(0.0, 30.0 * (1.0 - percentVisible), 0.0),
                    child: Padding(
                      padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                      child: Text(
                        viewModel.title ?? '',
                        style: TextStyle(
                          color: viewModel.titleColor ?? Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: FONT_SIZE_TITLE,
                        ),
                      ),
                    ),
                  ),
                  Transform(
                    transform: Matrix4.translationValues(0.0, 30.0 * (1.0 - percentVisible), 0.0),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 75.0),
                      child: Text(
                        viewModel.body ?? '',
                        textAlign: orientation == Orientation.portrait ? TextAlign.center :  TextAlign.start,
                        style: TextStyle(
                          color: viewModel.bodyColor ?? Colors.white,
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
}