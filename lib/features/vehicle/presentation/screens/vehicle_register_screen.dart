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
const _kColores = [
  'Blanco', 'Rojo', 'Azul', 'Negro', 'Verde', 'Amarillo', 'Gris', 'Naranja',
];

class _VehicleRegisterScreenState extends ConsumerState<VehicleRegisterScreen> {
  int _step = 0; // 0=datos, 1=tarjeta, 2=foto, 3=listo
  // Nada se persiste hasta "Finalizar": ahí se crea el vehículo y se suben los
  // dos documentos. Estos flags hacen el reintento idempotente si algo falla a
  // media subida (no recrea ni resube lo ya hecho).
  int _idVehiculo = 0;
  bool _tarjetaSubida = false;
  bool _fotoSubida = false;
  bool _enviando = false;

  final _placaController = TextEditingController();
  final _numeroSerieController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  String? _color;
  Municipio? _municipio;

  Uint8List? _tarjetaBytes;
  Uint8List? _fotoBytes;
  String? _error;

  @override
  void dispose() {
    _placaController.dispose();
    _numeroSerieController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    super.dispose();
  }

  // ───────── Pasos (nada se envía hasta "Finalizar") ─────────

  void _continuarDatos() {
    if (_placaController.text.trim().length < 3) {
      setState(() => _error = 'Escribe la placa del vehículo.');
      return;
    }
    if (_numeroSerieController.text.trim().length < 3) {
      setState(() => _error = 'Escribe el número de serie del vehículo.');
      return;
    }
    if (_municipio == null) {
      setState(() => _error = 'Selecciona tu municipio.');
      return;
    }
    setState(() {
      _error = null;
      _step = 1;
    });
  }

  void _continuarTarjeta() {
    if (_tarjetaBytes == null) {
      setState(() => _error = 'Toma o elige la foto de la tarjeta primero.');
      return;
    }
    setState(() {
      _error = null;
      _step = 2;
    });
  }

  /// Crea el vehículo y sube ambos documentos en un solo envío. Idempotente:
  /// si algo falla a media subida, reintenta sin recrear ni resubir lo hecho.
  Future<void> _finalizar() async {
    if (_fotoBytes == null) {
      setState(() => _error = 'Toma o elige la foto del vehículo primero.');
      return;
    }
    setState(() {
      _error = null;
      _enviando = true;
    });
    final vm = ref.read(vehicleViewModelProvider);
    try {
      if (_idVehiculo == 0) {
        final id = await vm.registrar(Vehiculo(
          placa: _placaController.text.trim().toUpperCase(),
          numeroSerie: _numeroSerieController.text.trim(),
          modelo: _modeloController.text.trim(),
          color: _color ?? '',
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
        _idVehiculo = id;
      }
      if (!_tarjetaSubida) {
        final ok = await vm.subirDocumento(
          idVehiculo: _idVehiculo,
          tipo: 'tarjeta-circulacion',
          bytes: _tarjetaBytes!,
          fileName: 'tarjeta-circulacion.jpg',
        );
        if (!mounted) return;
        if (!ok) {
          setState(() =>
              _error = vm.errorMessage ?? 'No se pudo subir la tarjeta.');
          return;
        }
        _tarjetaSubida = true;
      }
      if (!_fotoSubida) {
        final ok = await vm.subirDocumento(
          idVehiculo: _idVehiculo,
          tipo: 'foto-vehiculo',
          bytes: _fotoBytes!,
          fileName: 'foto-vehiculo.jpg',
        );
        if (!mounted) return;
        if (!ok) {
          setState(
              () => _error = vm.errorMessage ?? 'No se pudo subir la foto.');
          return;
        }
        _fotoSubida = true;
      }
      if (mounted) setState(() => _step = 3);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  // ───────── Imagen ─────────

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    final jpeg = await compressToJpeg(await picked.readAsBytes());
    if (!mounted) return;
    setState(() {
      _error = null;
      if (_step == 1) {
        _tarjetaBytes = jpeg;
      } else {
        _fotoBytes = jpeg;
      }
    });
  }

  // ───────── UI ─────────

  @override
  Widget build(BuildContext context) {
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
                child: _buildStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _datosStep();
      case 1:
        return _fotoStep(
          titulo: 'Tarjeta de circulación',
          ayuda: 'Toma una foto clara de la tarjeta de circulación del vehículo.',
          botonLabel: 'Continuar',
          bytes: _tarjetaBytes,
          onSubir: _continuarTarjeta,
        );
      case 2:
        return _fotoStep(
          titulo: 'Foto del vehículo',
          ayuda: 'Toma una foto del frente del mototaxi donde se vea la placa.',
          botonLabel: 'Finalizar registro',
          bytes: _fotoBytes,
          cargando: _enviando,
          onSubir: _finalizar,
        );
      default:
        return _listoStep();
    }
  }

  Widget _datosStep() {
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
        TextField(
          controller: _numeroSerieController,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Número de serie *',
            hintText: 'Serie / VIN de la unidad',
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
        DropdownButtonFormField<String>(
          initialValue: _color,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Color'),
          items: _kColores
              .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _color = v),
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
          label: 'Continuar',
          onPressed: _continuarDatos,
        ),
      ],
    );
  }

  Widget _fotoStep({
    required String titulo,
    required String ayuda,
    required String botonLabel,
    required Uint8List? bytes,
    required VoidCallback onSubir,
    bool cargando = false,
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
              image: bytes != null
                  ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
                  : null,
            ),
            child: bytes == null
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
          label: cargando ? 'Registrando…' : botonLabel,
          onPressed: cargando || bytes == null ? null : onSubir,
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: cargando
                ? null
                : () => setState(() {
                      _error = null;
                      _step -= 1;
                    }),
            child: const Text('Atrás'),
          ),
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
