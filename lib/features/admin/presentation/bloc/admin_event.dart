sealed class AdminEvent {
  const AdminEvent();
}

class AdminDashboardFetched extends AdminEvent {
  const AdminDashboardFetched();
}

class AdminMembersFetched extends AdminEvent {
  const AdminMembersFetched({this.search, this.page = 1});

  final String? search;
  final int page;
}

class AdminMemberDetailFetched extends AdminEvent {
  const AdminMemberDetailFetched(this.id);

  final int id;
}

class AdminMemberUpdated extends AdminEvent {
  const AdminMemberUpdated({required this.id, required this.data});

  final int id;
  final Map<String, dynamic> data;
}
