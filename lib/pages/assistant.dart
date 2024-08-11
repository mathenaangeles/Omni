import 'package:flutter/material.dart';

import '../widgets/custom_app_bar.dart';

class Assistant extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(),
      body: Center(
        child: Text('Assistant'),
      ),
    );
  }
}
