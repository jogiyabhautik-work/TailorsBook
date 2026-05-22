import 'package:flutter/material.dart';
import '../../providers/language_provider.dart';
import '../../providers/template_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/fabric_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/utils/app_refresh_controller.dart';

class AppRefreshControllerWrapper extends InheritedNotifier<AppRefreshController> {
  const AppRefreshControllerWrapper({super.key, required super.notifier, required super.child});
  static AppRefreshController of(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<AppRefreshControllerWrapper>()!.notifier!;
    } else {
      return context.getInheritedWidgetOfExactType<AppRefreshControllerWrapper>()!.notifier!;
    }
  }
}

class LanguageProviderWrapper extends InheritedNotifier<LanguageProvider> {
  const LanguageProviderWrapper({super.key, required super.notifier, required super.child});
  static LanguageProvider of(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<LanguageProviderWrapper>()!.notifier!;
    } else {
      return context.getInheritedWidgetOfExactType<LanguageProviderWrapper>()!.notifier!;
    }
  }
}

class TemplateProviderWrapper extends InheritedNotifier<TemplateProvider> {
  const TemplateProviderWrapper({super.key, required super.notifier, required super.child});
  static TemplateProvider of(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<TemplateProviderWrapper>()!.notifier!;
    } else {
      return context.getInheritedWidgetOfExactType<TemplateProviderWrapper>()!.notifier!;
    }
  }
}

class CustomerProviderWrapper extends InheritedNotifier<CustomerProvider> {
  const CustomerProviderWrapper({super.key, required super.notifier, required super.child});
  static CustomerProvider of(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<CustomerProviderWrapper>()!.notifier!;
    } else {
      return context.getInheritedWidgetOfExactType<CustomerProviderWrapper>()!.notifier!;
    }
  }
}

class OrderProviderWrapper extends InheritedNotifier<OrderProvider> {
  const OrderProviderWrapper({super.key, required super.notifier, required super.child});
  static OrderProvider of(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<OrderProviderWrapper>()!.notifier!;
    } else {
      return context.getInheritedWidgetOfExactType<OrderProviderWrapper>()!.notifier!;
    }
  }
}

class WorkerProviderWrapper extends InheritedNotifier<WorkerProvider> {
  const WorkerProviderWrapper({super.key, required super.notifier, required super.child});
  static WorkerProvider of(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<WorkerProviderWrapper>()!.notifier!;
    } else {
      return context.getInheritedWidgetOfExactType<WorkerProviderWrapper>()!.notifier!;
    }
  }
}

class FabricProviderWrapper extends InheritedNotifier<FabricProvider> {
  const FabricProviderWrapper({super.key, required super.notifier, required super.child});
  static FabricProvider of(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<FabricProviderWrapper>()!.notifier!;
    } else {
      return context.getInheritedWidgetOfExactType<FabricProviderWrapper>()!.notifier!;
    }
  }
}

class DashboardProviderWrapper extends InheritedNotifier<DashboardProvider> {
  const DashboardProviderWrapper({super.key, required super.notifier, required super.child});
  static DashboardProvider of(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<DashboardProviderWrapper>()!.notifier!;
    } else {
      return context.getInheritedWidgetOfExactType<DashboardProviderWrapper>()!.notifier!;
    }
  }
}
