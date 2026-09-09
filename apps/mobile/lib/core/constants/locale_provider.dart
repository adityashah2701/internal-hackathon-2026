import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('en');

  void setLocale(Locale newLocale) {
    state = newLocale;
  }
}

final NotifierProvider<LocaleNotifier, Locale> localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
