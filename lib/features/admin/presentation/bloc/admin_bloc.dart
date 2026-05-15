import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_error_handler.dart';
import '../../data/models/admin_model.dart';
import '../../data/repositories/admin_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  AdminBloc(this._repository) : super(const AdminInitial()) {
    on<AdminDashboardFetched>(_onDashboardFetched);
    on<AdminMembersFetched>(_onMembersFetched);
    on<AdminMemberDetailFetched>(_onMemberDetailFetched);
    on<AdminMemberUpdated>(_onMemberUpdated);
  }

  final AdminRepository _repository;

  Future<void> _onDashboardFetched(
    AdminDashboardFetched event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    try {
      final dashboard = await _repository.getDashboard();
      emit(AdminDashboardLoaded(dashboard: dashboard));
    } catch (e) {
      emit(AdminFailure(ApiErrorHandler.getMessage(e)));
    }
  }

  Future<void> _onMembersFetched(
    AdminMembersFetched event,
    Emitter<AdminState> emit,
  ) async {
    final previous = state;
    final append = event.page > 1 && previous is AdminMembersLoaded;
    if (!append) {
      emit(const AdminLoading(message: 'Memuat data anggota...'));
    }
    try {
      final model = await _repository.getMembers(
        search: event.search,
        page: event.page,
      );
      if (append) {
        emit(
          AdminMembersLoaded(
            page: AdminMemberPageModel(
              items: [...previous.page.items, ...model.items],
              currentPage: model.currentPage,
              lastPage: model.lastPage,
              total: model.total,
            ),
          ),
        );
      } else {
        emit(AdminMembersLoaded(page: model));
      }
    } catch (e) {
      emit(AdminFailure(ApiErrorHandler.getMessage(e)));
    }
  }

  Future<void> _onMemberDetailFetched(
    AdminMemberDetailFetched event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading(message: 'Memuat detail anggota...'));
    try {
      final member = await _repository.getMemberDetail(event.id);
      emit(AdminMemberDetailLoaded(member: member));
    } catch (e) {
      emit(AdminFailure(ApiErrorHandler.getMessage(e)));
    }
  }

  Future<void> _onMemberUpdated(
    AdminMemberUpdated event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading(message: 'Menyimpan...'));
    try {
      await _repository.updateMember(event.id, event.data);
      emit(const AdminSuccess('Anggota berhasil diperbarui'));
      final member = await _repository.getMemberDetail(event.id);
      emit(AdminMemberDetailLoaded(member: member));
    } catch (e) {
      emit(AdminFailure(ApiErrorHandler.getMessage(e)));
    }
  }
}
