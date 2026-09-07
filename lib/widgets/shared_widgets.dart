import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

/// Muestra una imagen desde un `XFile` (galería/cámara ya elegida) de forma
/// compatible con Android, iOS y Web: en vez de `Image.file` (que depende
/// de `dart:io`, inexistente en Web), lee los bytes con `readAsBytes()` y
/// pinta con `Image.memory`, que funciona en todas las plataformas.
class XFileImage extends StatelessWidget {
  final XFile file;
  final BoxFit fit;

  const XFileImage({super.key, required this.file, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(color: AppColors.border);
        }
        return Image.memory(snapshot.data!, fit: fit);
      },
    );
  }
}

/// Campo circular para foto de perfil (obligatoria). Abre un menú para
/// elegir entre Galería o Cámara usando `image_picker` (acceso real al
/// dispositivo, no una galería simulada).
class ProfilePhotoPicker extends StatelessWidget {
  final XFile? localFile;
  final String? networkUrl;
  final bool required;
  final ValueChanged<XFile> onPicked;

  const ProfilePhotoPicker({
    super.key,
    required this.localFile,
    required this.networkUrl,
    required this.onPicked,
    this.required = true,
  });

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SourceSheet(),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1200);
    if (file != null) onPicked(file);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = localFile != null || (networkUrl != null && networkUrl!.isNotEmpty);
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pick(context),
          child: Stack(
            children: [
              ClipOval(
                child: Container(
                  width: 110,
                  height: 110,
                  color: AppColors.primarySoft,
                  child: localFile != null
                      ? XFileImage(file: localFile!)
                      : (networkUrl != null && networkUrl!.isNotEmpty)
                          ? Image.network(networkUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.person_rounded, size: 48, color: AppColors.primaryDark),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasImage ? 'Toca para cambiar la foto' : 'Foto de perfil obligatoria',
          style: TextStyle(
            fontSize: 12.5,
            color: hasImage ? AppColors.textLight : AppColors.danger,
            fontWeight: hasImage ? FontWeight.w400 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Selecciona una foto', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
            title: const Text('Tomar una foto'),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
        ],
      ),
    );
  }
}

/// Campo rectangular para foto de mascota o carnet de vacunación.
/// Permite imagen (galería/cámara) o documento (PDF) mediante `file_picker`.
class MediaUploadField extends StatelessWidget {
  final String label;
  final IconData icon;
  final XFile? localFile;
  final String? networkUrl;
  final bool allowPdf;
  final ValueChanged<XFile> onPicked;

  const MediaUploadField({
    super.key,
    required this.label,
    required this.icon,
    required this.localFile,
    required this.networkUrl,
    required this.onPicked,
    this.allowPdf = false,
  });

  Future<void> _handleTap(BuildContext context) async {
    final option = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 18),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Elegir foto de la galería'),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: const Text('Tomar una foto'),
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
            if (allowPdf)
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
                title: const Text('Subir archivo PDF'),
                onTap: () => Navigator.of(ctx).pop('pdf'),
              ),
          ],
        ),
      ),
    );

    if (option == null) return;

    if (option == 'pdf') {
      // withData: true es indispensable en Web: ahí no existe una ruta de
      // archivo real, así que el plugin solo puede devolver los bytes.
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      final picked = files.isNotEmpty ? files.single : null;
      if (picked != null) {
        // file_picker v12: `bytes` ya no es un getter síncrono; hay que
        // leerlo con `readAsBytes()`, que funciona tanto si vino con
        // datos en memoria (Web) como si solo vino con `path` (IO).
        final bytes = await picked.readAsBytes();
        onPicked(XFile.fromData(bytes, name: picked.name, mimeType: 'application/pdf'));
      }
      return;
    }

    final source = option == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
    if (file != null) onPicked(file);
  }

  bool get _isPdf =>
      (localFile?.name.toLowerCase().endsWith('.pdf') ?? false) ||
      (networkUrl?.toLowerCase().contains('.pdf') ?? false);

  @override
  Widget build(BuildContext context) {
    final hasFile = localFile != null || (networkUrl != null && networkUrl!.isNotEmpty);
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasFile ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: !hasFile
                    ? Container(color: AppColors.primarySoft, child: Icon(icon, color: AppColors.primaryDark))
                    : _isPdf
                        ? Container(
                            color: AppColors.dangerSoft,
                            child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.danger),
                          )
                        : localFile != null
                            ? XFileImage(file: localFile!)
                            : Image.network(networkUrl!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textDark)),
                  const SizedBox(height: 3),
                  Text(
                    hasFile ? 'Archivo seleccionado' : 'Toca para seleccionar (galería, cámara o PDF)',
                    style: TextStyle(color: hasFile ? AppColors.primaryDark : AppColors.textLight, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

/// Badge de estado reutilizable (pendiente / aceptado / rechazado).
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const StatusBadge({super.key, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class LoadingButton extends StatelessWidget {
  final bool loading;
  final String label;
  final VoidCallback? onPressed;

  const LoadingButton({super.key, required this.loading, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
            : Text(label),
      ),
    );
  }
}
