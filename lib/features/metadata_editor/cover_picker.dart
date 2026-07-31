import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// De donde se toma la imagen de portada (requerimiento seccion 7.2).
enum CoverSource { gallery, camera, files, clipboard }

/// Resultado del selector: bytes ya recortados y listos para incrustar.
class PickedCover {
  const PickedCover({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

/// Elige una imagen, la recorta en cuadrado y devuelve los bytes.
///
/// El recorte, la rotacion, el zoom, el encuadre y la calidad los aporta el
/// recortador nativo; la validacion y el limite de tamano los aplica el motor
/// antes de escribir (requerimiento secciones 7.2 y 16).
Future<PickedCover?> pickCoverImage(
  BuildContext context,
  WidgetRef ref, {
  required CoverSource source,
}) async {
  final sourceFile = await _resolveSourceFile(context, ref, source);
  if (sourceFile == null) return null;

  final cropped = await ImageCropper().cropImage(
    sourcePath: sourceFile.path,
    maxWidth: _recommendedSize,
    maxHeight: _recommendedSize,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: _quality,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: AppStrings.cover,
        lockAspectRatio: true,
        hideBottomControls: false,
      ),
    ],
  );

  if (cropped == null) return null;

  final bytes = await File(cropped.path).readAsBytes();
  return PickedCover(bytes: bytes, mimeType: 'image/jpeg');
}

Future<File?> _resolveSourceFile(
  BuildContext context,
  WidgetRef ref,
  CoverSource source,
) async {
  switch (source) {
    case CoverSource.gallery:
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      return picked == null ? null : File(picked.path);

    case CoverSource.camera:
      final picked = await ImagePicker().pickImage(source: ImageSource.camera);
      return picked == null ? null : File(picked.path);

    case CoverSource.files:
      // El selector de documentos del sistema permite elegir imagenes que no
      // estan indexadas en la galeria.
      final engine = ref.read(engineProvider);
      final document = await engine.api.pickDocument(const ['image/*']);
      if (document == null) return null;
      final bytes = await engine.api.readDocumentBytes(document.uri);
      return _writeTempFile(bytes, 'documento');

    case CoverSource.clipboard:
      final bytes = await ref.read(engineProvider).api.getClipboardImage();
      if (bytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay ninguna imagen en el portapapeles'),
            ),
          );
        }
        return null;
      }
      return _writeTempFile(bytes, 'portapapeles');
  }
}

Future<File> _writeTempFile(Uint8List bytes, String name) async {
  final directory = await getTemporaryDirectory();
  final file = File(
    p.join(
      directory.path,
      '$name-${DateTime.now().millisecondsSinceEpoch}.jpg',
    ),
  );
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

/// Tamano recomendado por el requerimiento seccion 7.2.
const _recommendedSize = 1000;
const _quality = 90;
