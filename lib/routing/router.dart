import 'package:flutter_production_grade/routing/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) =>
    GoRouter(routes: $appRoutes, initialLocation: const HomeRoute().location);
