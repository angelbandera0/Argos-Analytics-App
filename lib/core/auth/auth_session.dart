import 'package:flutter/foundation.dart';

import 'app_role.dart';
import 'app_user.dart';
import 'mock_users_repository.dart';
import 'permission.dart';

/// Holds the currently logged-in user and answers every permission
/// question in the app ("can this user read/write/edit/delete this
/// module option?"). A single global instance ([AuthSession.instance])
/// is used because auth state needs to be reachable from the router
/// (redirect guard), the sidebar (menu filtering) and every screen
/// (action-level permission checks) without threading it through
/// constructors.
///
/// It's a [ChangeNotifier] so it can be passed as GoRouter's
/// `refreshListenable` (re-evaluates redirects on login/logout) and
/// listened to directly by widgets via `AnimatedBuilder`.
class AuthSession extends ChangeNotifier {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Looks up the user by email and checks the (mock, plaintext)
  /// password. Returns the matched user on success, or `null` on
  /// invalid credentials — callers show their own error UI for that.
  AppUser? login(String email, String password) {
    final user = findUserByEmail(email);
    if (user == null || user.password != password || !user.active) return null;
    _currentUser = user;
    notifyListeners();
    return user;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  /// Re-reads the current user from the repository — call after editing
  /// your own permissions/profile so the sidebar reflects it immediately.
  void refreshCurrentUser() {
    final id = _currentUser?.id;
    if (id == null) return;
    final fresh = findUserById(id);
    if (fresh != null) {
      _currentUser = fresh;
      notifyListeners();
    }
  }

  /// Whether the current user can perform [action] on [moduleId]/[optionId].
  /// SuperAdmin always returns true.
  bool can(String moduleId, String optionId, [PermissionAction action = PermissionAction.read]) {
    final user = _currentUser;
    if (user == null) return false;
    if (user.role.hasUnrestrictedAccess) return true;
    return user.permissions.any((p) => p.moduleId == moduleId && p.optionId == optionId && p.actions.contains(action));
  }

  /// Whether the current user can see the module at all (has read access
  /// to at least one of its options).
  bool canModule(String moduleId) {
    final user = _currentUser;
    if (user == null) return false;
    if (user.role.hasUnrestrictedAccess) return true;
    return user.permissions.any((p) => p.moduleId == moduleId && p.canRead);
  }
}
