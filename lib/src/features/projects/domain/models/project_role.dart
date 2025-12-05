/// Role of a member in a project
enum ProjectRole {
  /// Project owner - full control
  owner,

  /// Can manage members and project settings
  admin,

  /// Can create and edit tasks
  editor,

  /// Can only view tasks
  viewer;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case ProjectRole.owner:
        return 'Owner';
      case ProjectRole.admin:
        return 'Admin';
      case ProjectRole.editor:
        return 'Editor';
      case ProjectRole.viewer:
        return 'Viewer';
    }
  }

  /// Icon for UI
  String get icon {
    switch (this) {
      case ProjectRole.owner:
        return '👑';
      case ProjectRole.admin:
        return '⚙️';
      case ProjectRole.editor:
        return '✏️';
      case ProjectRole.viewer:
        return '👁️';
    }
  }

  /// Check if role has admin permissions
  bool get isAdmin => this == ProjectRole.owner || this == ProjectRole.admin;

  /// Check if role can edit
  bool get canEdit =>
      this == ProjectRole.owner ||
      this == ProjectRole.admin ||
      this == ProjectRole.editor;
}
