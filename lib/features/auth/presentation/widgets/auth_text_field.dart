import 'package:flutter/material.dart';
import '../../../../core/widgets/app_form_field.dart';

/// Thin alias kept for backwards compatibility / semantic naming inside
/// the auth feature. The actual implementation lives in the shared
/// [AppFormField] so login and every dialog form share one styled field.
typedef AuthTextField = AppFormField;
