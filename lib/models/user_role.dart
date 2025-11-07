enum UserRole {
  admin,
  clinician,
  patient,
  receptionist,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.clinician:
        return 'Clinician';
      case UserRole.patient:
        return 'Patient';
      case UserRole.receptionist:
        return 'Receptionist';
    }
  }

  String get loginTitle {
    switch (this) {
      case UserRole.admin:
        return 'Admin Login';
      case UserRole.clinician:
        return 'Clinician Login';
      case UserRole.patient:
        return 'Patient Portal';
      case UserRole.receptionist:
        return 'Receptionist Login';
    }
  }

  String get description {
    switch (this) {
      case UserRole.admin:
        return 'Full system access and management';
      case UserRole.clinician:
        return 'Access to patient records and analysis tools';
      case UserRole.patient:
        return 'View your own medical records';
      case UserRole.receptionist:
        return 'Patient registration and scheduling';
    }
  }

  bool get canAccessPatientRecords {
    return this == UserRole.admin || this == UserRole.clinician;
  }

  bool get canCreatePatients {
    return this == UserRole.admin || this == UserRole.receptionist || this == UserRole.clinician;
  }

  bool get canPerformAnalysis {
    return this == UserRole.admin || this == UserRole.clinician;
  }
}

