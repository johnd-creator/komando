import '../../data/models/admin_model.dart';

sealed class AdminState {
  const AdminState();
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminLoading extends AdminState {
  const AdminLoading({this.message = 'Memuat data admin...'});

  final String message;
}

class AdminDashboardLoaded extends AdminState {
  const AdminDashboardLoaded({required this.dashboard});

  final AdminDashboardModel dashboard;
}

class AdminMembersLoaded extends AdminState {
  const AdminMembersLoaded({required this.page});

  final AdminMemberPageModel page;
}

class AdminMemberDetailLoaded extends AdminState {
  const AdminMemberDetailLoaded({required this.member});

  final AdminMemberModel member;
}

class AdminSuccess extends AdminState {
  const AdminSuccess(this.message);

  final String message;
}

class AdminFailure extends AdminState {
  const AdminFailure(this.message);

  final String message;
}
