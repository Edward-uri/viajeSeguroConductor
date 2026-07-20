import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/data/providers/municipio_provider.dart';
import '../../../../shared/domain/entities/municipio.dart';
import '../../../../shared/utils/image_utils.dart';
import '../../../../theme/jala_theme.dart';
import '../../domain/entities/vehiculo.dart';
import '../provider/vehicle_viewmodel.dart';

/// Alta del vehículo en 3 pasos guiados (datos → tarjeta de circulación → foto),
/// con un stepper visible para que el conductor sepa cuánto le falta.
class VehicleRegisterScreen extends ConsumerStatefulWidget {
  const VehicleRegisterScreen({super.key});

  @override
  ConsumerState<VehicleRegisterScreen> createState() =>
      _VehicleRegisterScreenState();
}

const _kPasos = ['Datos', 'Tarjeta', 'Foto'];

class _VehicleRegisterScreenState extends ConsumerState<VehicleRegisterScreen> {
  int _step = 0; // 0=datos, 1=tarjeta, 2=foto, 3=listo
  int _idVehiculo = 0;

  final _placaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _colorController = TextEditingController();
  final _anioController = TextEditingController();
  Municipio? _municipio;

  Uint8List? _docBytes; // foto del paso actual (tarjeta o vehículo)
  String _docExt = 'jpg';
  String? _error;

  @override
  void dispose() {
    _placaController.dispose();
    _modeloController.dispose();
    _colorController.dispose();
    _anioController.dispose();
    super.dispose();
  }

  // ───────── Pasos ─────────

  Future<void> _guardarDatos() async {
    setState(() => _error = null);
    if (_placaController.text.trim().length < 3) {
      setState(() => _error = 'Escribe la placa del vehículo.');
      return;
    }
    if (_municipio == null) {
      setState(() => _error = 'Selecciona tu municipio.');
      return;
    }
    final vm = ref.read(vehicleViewModelProvider);
    final id = await vm.registrar(Vehiculo(
      placa: _placaController.text.trim().toUpperCase(),
      modelo: _modeloController.text.trim(),
      color: _colorController.text.trim(),
      anio: int.tryParse(_anioController.text.trim()) ?? 0,
      idMunicipio: _municipio!.idMunicipio,
      municipio: _municipio!.nombre,
      status: VehicleStatus.incomplete,
    ));
    if (!mounted) return;
    if (id == 0) {
      setState(() => _error = vm.errorMessage ?? 'No se pudo registrar.');
      return;
    }
    setState(() {
      _idVehiculo = id;
      _docBytes = null;
      _step = 1;
    });
  }

  Future<void> _subirDocPaso(String tipo, int siguiente) async {
    if (_docBytes == null) {
      setState(() => _error = 'Toma o elige una foto primero.');
      return;
    }
    setState(() => _error = null);
    final vm = ref.read(vehicleViewModelProvider);
    final ok = await vm.subirDocumento(
      idVehiculo: _idVehiculo,
      tipo: tipo,
      bytes: _docBytes!,
      fileName: '$tipo.$_docExt',
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = vm.errorMessage ?? 'No se pudo subir.');
      return;
    }
    setState(() {
      _docBytes = null;
      _step = siguiente;
    });
  }

  // ───────── Imagen ─────────

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    final jpeg = await compressToJpeg(await picked.readAsBytes());
    if (!mounted) return;
    setState(() {
      _error = null;
      _docBytes = jpeg;
      _docExt = 'jpg';
    });
  }

  // ───────── UI ─────────

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(vehicleViewModelProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_step >= 3 ? 'Vehículo registrado' : 'Registrar vehículo'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_step < 3) _StepperHeader(current: _step),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: _buildStep(vm),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(VehicleViewModel vm) {
    switch (_step) {
      case 0:
        return _datosStep(vm);
      case 1:
        return _fotoStep(
          titulo: 'Tarjeta de circulación',
          ayuda: 'Toma una foto clara de la tarjeta de circulación del vehículo.',
          botonLabel: 'Subir y continuar',
          vm: vm,
          onSubir: () => _subirDocPaso('tarjeta-circulacion', 2),
        );
      case 2:
        return _fotoStep(
          titulo: 'Foto del vehículo',
          ayuda: 'Toma una foto del frente del mototaxi donde se vea la placa.',
          botonLabel: 'Subir y finalizar',
          vm: vm,
          onSubir: () => _subirDocPaso('foto-vehiculo', 3),
        );
      default:
        return _listoStep();
    }
  }

  Widget _datosStep(VehicleViewModel vm) {
    final municipios = ref.watch(municipiosProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PasoTitulo('Datos del vehículo', 'Llena los datos de tu mototaxi.'),
        const SizedBox(height: 20),
        TextField(
          controller: _placaController,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Placa *',
            hintText: 'ABC-123',
          ),
        ),
        const SizedBox(height: 16),
        municipios.when(
          data: (lista) => DropdownButtonFormField<Municipio>(
            initialValue: _municipio,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Municipio *'),
            items: lista
                .map((m) => DropdownMenuItem<Municipio>(
                      value: m,
                      child: Text('${m.nombre}, ${m.estado}'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _municipio = v),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => Text('No se pudieron cargar los municipios',
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _modeloController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Modelo',
            hintText: 'Italika, Bajaj…',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _colorController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Color'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _anioController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Año'),
        ),
        if (_error != null) ...[const SizedBox(height: 16), _ErrorBox(_error!)],
        const SizedBox(height: 28),
        GradientButton(
          label: vm.isSaving ? 'Guardando…' : 'Continuar',
          onPressed: vm.isSaving ? null : _guardarDatos,
        ),
      ],
    );
  }

  Widget _fotoStep({
    required String titulo,
    required String ayuda,
    required String botonLabel,
    required VehicleViewModel vm,
    required VoidCallback onSubir,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PasoTitulo(titulo, ayuda),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => _pickImage(ImageSource.camera),
          child: Container(
            height: 260,
            width: double.infinity,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant, width: 2),
              image: _docBytes != null
                  ? DecorationImage(image: MemoryImage(_docBytes!), fit: BoxFit.cover)
                  : null,
            ),
            child: _docBytes == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined,
                            size: 60,
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('Tocar para tomar foto',
                            style: TextStyle(color: context.brand.greyDark)),
                      ],
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _pickImage(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Elegir de la galería'),
        ),
        if (_error != null) ...[const SizedBox(height: 8), _ErrorBox(_error!)],
        const SizedBox(height: 12),
        const _Tip('Buena iluminación, sin reflejos'),
        const _Tip('El documento completo y enfocado'),
        const _Tip('Todos los datos legibles'),
        const SizedBox(height: 24),
        GradientButton(
          label: vm.isSaving ? 'Subiendo…' : botonLabel,
          onPressed: vm.isSaving || _docBytes == null ? null : onSubir,
        ),
      ],
    );
  }

  Widget _listoStep() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: context.brand.successLight,
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.check_circle, color: context.brand.success, size: 56),
          ),
          const SizedBox(height: 24),
          Text(
            '¡Vehículo registrado!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu mototaxi quedó en revisión. Te avisaremos cuando esté aprobado para que puedas recibir viajes.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: context.brand.greyDark, height: 1.4),
          ),
          const SizedBox(height: 36),
          GradientButton(
            label: 'Entendido',
            onPressed: () => context.go(AppRoutes.vehicles),
          ),
        ],
      ),
    );
  }
}

// ───────── Widgets de apoyo ─────────

class _StepperHeader extends StatelessWidget {
  final int current;
  const _StepperHeader({required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Column(
        children: [
          Row(
            children: List.generate(_kPasos.length * 2 - 1, (i) {
              if (i.isOdd) {
                final done = current > i ~/ 2;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: done
                        ? context.brand.success
                        : context.brand.greyBorder,
                  ),
                );
              }
              final idx = i ~/ 2;
              final done = idx < current;
              final active = idx == current;
              return _StepDot(
                numero: idx + 1,
                label: _kPasos[idx],
                done: done,
                active: active,
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            'Paso ${current + 1} de ${_kPasos.length}',
            style: TextStyle(
                fontSize: 12,
                color: context.brand.greyDark,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int numero;
  final String label;
  final bool done;
  final bool active;
  const _StepDot({
    required this.numero,
    required this.label,
    required this.done,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = done
        ? context.brand.success
        : active
            ? JalaBrand.amber
            : context.brand.greyBorder;
    final Color fg =
        (done || active) ? Colors.white : context.brand.greyDark;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : Text('$numero',
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? context.colors.onSurface : context.brand.greyDark,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PasoTitulo extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  const _PasoTitulo(this.titulo, this.subtitulo);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface)),
        const SizedBox(height: 6),
        Text(subtitulo,
            style: TextStyle(fontSize: 14, color: context.brand.greyDark)),
      ],
    );
  }
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check, size: 16, color: context.brand.success),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(fontSize: 13, color: context.brand.greyDark)),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.brand.destructiveLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              size: 20, color: context.brand.destructive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: 13, color: context.brand.destructive)),
          ),
        ],
      ),
    );
  }
}
