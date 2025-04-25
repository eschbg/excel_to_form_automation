import 'package:flutter/material.dart';

class WidgetRebirth extends StatefulWidget {
  const WidgetRebirth({Key? key, required Widget materialApp})
      : _child = materialApp,
        super(key: key);
  final Widget _child;

  @override
  State<WidgetRebirth> createState() => _WidgetRebirthState();

/* This method will returns the State object of the nearest ancestor StatefulWidget widget that is an instance of the given type T.*/
  static void createRebirth({required BuildContext context}) {
    context.findAncestorStateOfType<_WidgetRebirthState>()!.restartApp();
  }
}

class _WidgetRebirthState extends State<WidgetRebirth> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() => key = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    /*What is KeyedSubtree?
    * It is a widget which is used to build its child with the help of a key
    */
    return KeyedSubtree(
      key: key,
      child: widget._child,
    );
  }
}
