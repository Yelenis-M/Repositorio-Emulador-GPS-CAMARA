// Archivo: lib/screens/hardware_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/location_service.dart';

class HardwareScreen extends StatefulWidget {
  const HardwareScreen({super.key});

  @override
  State<HardwareScreen> createState() => _HardwareScreenState();
}

class _HardwareScreenState extends State<HardwareScreen> {
  // Paleta de colores: café, rosa y verde
  static const Color _cafe = Color(0xFF6F4E37);       // Café
  static const Color _cafeOscuro = Color(0xFF4E342E); // Café oscuro
  static const Color _rosa = Color(0xFFE8A0BF);       // Rosa
  static const Color _rosaSuave = Color(0xFFF8D7E3);  // Rosa suave
  static const Color _verde = Color(0xFF7BA05B);     // Verde
  static const Color _verdeSuave = Color(0xFFD4E4C8); // Verde suave

  // Servicios y controladores de hardware
  final LocationService _locationService = LocationService();
  final ImagePicker _picker = ImagePicker();

  // Estado de la pantalla
  Position? _currentPosition;
  File? _capturedImage;
  bool _isLoading = false;

  // Variables para el Reto 5 (Seguimiento en vivo)
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;

  @override
  void dispose() {
    // Cancelamos el stream para evitar fugas de memoria al salir de la pantalla
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // Muestra un mensaje breve en la parte inferior
  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: _cafeOscuro,
      ),
    );
  }

  // Lee el GPS (Posición puntual)
  Future<void> _fetchLocation() async {
    if (_isTracking) {
      _stopTracking();
    }
    setState(() => _isLoading = true);
    try {
      final position = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() => _currentPosition = position);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error de hardware: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // RETO 5: Iniciar o detener el seguimiento en vivo
  Future<void> _toggleLiveTracking() async {
    if (_isTracking) {
      _stopTracking();
    } else {
      setState(() => _isLoading = true);
      try {
        final stream = await _locationService.getPositionStream();
        if (!mounted) return;

        _positionStreamSubscription = stream.listen((Position position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
            });
          }
        });

        setState(() {
          _isTracking = true;
          _isLoading = false;
        });
        _showMessage('Seguimiento en vivo iniciado.');
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showMessage('Error al iniciar seguimiento: $e');
      }
    }
  }

  void _stopTracking() {
    _positionStreamSubscription?.cancel();
    setState(() {
      _isTracking = false;
    });
    _showMessage('Seguimiento en vivo detenido.');
  }

  // Activa la cámara del teléfono (Cámara)
  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (photo != null && mounted) {
        setState(() => _capturedImage = File(photo.path));
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo usar la cámara: $e');
    }
  }

  // RETO 2: Elegir una foto de la galería
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (photo != null && mounted) {
        setState(() => _capturedImage = File(photo.path));
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo acceder a la galería: $e');
    }
  }

  // RETO 4: Borrar foto y coordenadas, reiniciando el estado
  void _resetState() {
    if (_isTracking) {
      _stopTracking();
    }
    setState(() {
      _currentPosition = null;
      _capturedImage = null;
    });
    _showMessage('Estado reiniciado correctamente.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _rosaSuave,
      appBar: AppBar(
        title: const Text(
          'Laboratorio: GPS y Cámara',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _cafe,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Botón en la barra superior para el Reto 4 (Reiniciar)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reiniciar Estado',
            onPressed: _resetState,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ----- MÓDULO DE CÁMARA -----
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: _verdeSuave,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _verde, width: 2),
              ),
              child: _capturedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_capturedImage!, fit: BoxFit.cover),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.camera_alt, size: 50, color: _verde),
                          SizedBox(height: 8),
                          Text(
                            'Sin fotografía capturada',
                            style: TextStyle(color: _cafeOscuro),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            
            // Botones de cámara y galería (RETO 2)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera, color: Colors.white),
                    label: const Text(
                      'Tomar Foto',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _verde,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromGallery, // Reto 2
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text(
                      'Galería',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _verde,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 40, thickness: 2, color: _rosa),

            // ----- MÓDULO DE GEOLOCALIZACIÓN -----
            Card(
              elevation: 4,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: _rosa, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _isTracking 
                          ? 'Datos de GPS (En Vivo 🟢)' 
                          : 'Datos de Geolocalización (GPS)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _cafeOscuro,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading)
                      const CircularIndicatorWithText()
                    else if (_currentPosition != null)
                      Text(
                        'Latitud: ${_currentPosition!.latitude}\n'
                        'Longitud: ${_currentPosition!.longitude}\n'
                        // RETO 1: Altitud y velocidad
                        'Altitud: ${_currentPosition!.altitude.toStringAsFixed(2)} m\n'
                        'Velocidad: ${_currentPosition!.speed.toStringAsFixed(2)} m/s\n'
                        // RETO 3: Fecha y hora de lectura
                        'Fecha/Hora: ${_currentPosition!.timestamp}\n'
                        'Precisión: ${_currentPosition!.accuracy.toStringAsFixed(2)} metros',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: _cafeOscuro,
                        ),
                      )
                    else
                      const Text(
                        'Coordenadas no obtenidas todavía.',
                        style: TextStyle(color: _cafeOscuro),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Botón: Obtener posición actual
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _fetchLocation,
              icon: const Icon(Icons.location_on, color: Colors.white),
              label: const Text(
                'Obtener Posición GPS Actual',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _cafe,
                disabledBackgroundColor: _rosa,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Botón: Seguimiento en vivo (RETO 5)
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _toggleLiveTracking,
              icon: Icon(
                _isTracking ? Icons.stop : Icons.directions_walk,
                color: Colors.white,
              ),
              label: Text(
                _isTracking ? 'Detener Seguimiento en Vivo' : 'Iniciar Seguimiento en Vivo',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTracking ? Colors.redAccent : _cafeOscuro,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Botón: Borrar datos / Reiniciar estado (RETO 4)
            OutlinedButton.icon(
              onPressed: _resetState,
              icon: const Icon(Icons.delete_sweep, color: _cafeOscuro),
              label: const Text(
                'Borrar Foto y Coordenadas',
                style: TextStyle(color: _cafeOscuro),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _cafe, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para indicador de carga de GPS
class CircularIndicatorWithText extends StatelessWidget {
  const CircularIndicatorWithText({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7BA05B)),
        ),
        SizedBox(height: 8),
        Text(
          'Conectando con satélites GPS...',
          style: TextStyle(color: Color(0xFF4E342E)),
        ),
      ],
    );
  }
}