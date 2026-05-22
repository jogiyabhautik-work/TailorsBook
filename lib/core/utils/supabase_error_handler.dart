import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseError {
  final String userMessage;
  final bool isNetworkError;
  final bool isAuthError;
  final bool isDatabaseError;

  SupabaseError({
    required this.userMessage,
    this.isNetworkError = false,
    this.isAuthError = false,
    this.isDatabaseError = false,
  });
}

SupabaseError classifySupabaseError(dynamic error) {
  final errorStr = error.toString().toLowerCase();

  if (error is TimeoutException || errorStr.contains('timeout') || errorStr.contains('timed out')) {
    return SupabaseError(
      userMessage: 'Server took too long to respond. Please try again.',
      isNetworkError: true,
    );
  }

  if (errorStr.contains('failed host lookup') ||
      errorStr.contains('no address associated') ||
      errorStr.contains('connection refused') ||
      errorStr.contains('connection closed') ||
      errorStr.contains('socketexception') ||
      errorStr.contains('network is unreachable')) {
    return SupabaseError(
      userMessage: 'No internet connection. Please check your network.',
      isNetworkError: true,
    );
  }

  if (error is PostgrestException) {
    final code = error.code?.toLowerCase() ?? '';
    final message = error.message.toLowerCase();

    if (code == '42501' || code == '401' || code == '403' ||
        message.contains('permission denied') ||
        message.contains('row-level security') ||
        message.contains('policy') ||
        message.contains('jwt')) {
      return SupabaseError(
        userMessage: 'Permission denied. Please sign in again.',
        isAuthError: true,
      );
    }

    if ((code == '23502' || code == '42703' || message.contains('column') || message.contains('not null')) &&
        (errorStr.contains('column') && errorStr.contains('does not exist') ||
         errorStr.contains('null value in column') ||
         errorStr.contains('violates not-null'))) {
      return SupabaseError(
        userMessage: 'Data sync issue. Please update your app or contact support.',
        isDatabaseError: true,
      );
    }
  }

  return SupabaseError(
    userMessage: 'Something went wrong. Please try again.',
    isDatabaseError: true,
  );
}
