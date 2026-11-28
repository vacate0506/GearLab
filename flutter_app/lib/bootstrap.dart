import 'package:flutter/widgets.dart';

import 'app/gearlab_app.dart';
import 'platform/platform_factory.dart';
import 'presentation/editor/editor_controller.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final GearLabController controller = GearLabController(createAppPlatform());
  await controller.initialize();
  runApp(GearLabApp(controller: controller));
}
