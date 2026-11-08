import 'package:flutter/foundation.dart';
import '../../domain/models/game_models.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/use_cases/registrar_sesion_use_case.dart';
import '../widgets/ui_state.dart';

class SessionViewModel extends ChangeNotifier {
  final GameRepository _repository;
  final RegistrarSesionUseCase _registrarSesionUseCase;

  SessionViewModel(this._repository, this._registrarSesionUseCase);

  ViewState _state = ViewState.loading;
  String? _errorMessage;
  bool _isSubmitting = false;
  List<SesionJuego> _sesiones = [];

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;
  List<SesionJuego> get sesiones => _sesiones;

  Future<void> cargarSesiones({int? videojuegoId}) async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _sesiones = await _repository.getSesiones(videojuegoId: videojuegoId);
      if (_sesiones.isEmpty) {
        _state = ViewState.empty;
      } else {
        _state = ViewState.success;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = ViewState.error;
    }
    notifyListeners();
  }

  Future<bool> registrarNuevaSesion({
    required int? videojuegoId,
    required int? plataformaId,
    required int minutosJugados,
    required String notas,
    int? filtroVideojuegoIdActual,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _registrarSesionUseCase.execute(
        videojuegoId: videojuegoId,
        plataformaId: plataformaId,
        minutosJugados: minutosJugados,
        notas: notas,
      );
      _isSubmitting = false;
      await cargarSesiones(videojuegoId: filtroVideojuegoIdActual);
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}