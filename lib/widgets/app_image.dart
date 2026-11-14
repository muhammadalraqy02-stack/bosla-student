// عرض صور الدليل بكل صيغها:
//  asset:xxx  صورة مضمّنة داخل التطبيق
//  https://…  رابط Supabase (مع نسخة مخبأة على الجهاز + محاولة بديلة للحاويات الخاصة)
//  media:id   صورة base64 قديمة داخل Firebase
//  data:image صورة base64 مباشرة

import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import '../app_state.dart';

class ImagePlaceholder extends StatelessWidget {
  final bool loading;
  const ImagePlaceholder({super.key, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF17233B), Color(0xFF1D2B46)]
              : const [Color(0xFFEEF3FA), Color(0xFFDCE7F5)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        loading ? Icons.hourglass_empty : Icons.image_outlined,
        color: const Color(0xFF7185A3),
        size: 30,
      ),
    );
  }
}

final Map<String, Uint8List> _dataCache = {};

Uint8List? _decodeCached(String ref) {
  final hit = _dataCache[ref];
  if (hit != null) return hit;
  final b = AppState.decodeDataUrl(ref);
  if (b != null) {
    if (_dataCache.length > 40) _dataCache.remove(_dataCache.keys.first);
    _dataCache[ref] = b;
  }
  return b;
}

class AppImage extends StatelessWidget {
  final String ref;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// لاحقة تُضاف إلى الرابط لإبطال النسخة المخبأة عند تغيّر الصورة (تُستخدم للإعلانات)
  final String cacheVersion;

  const AppImage(
    this.ref, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheVersion = '',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, height: height, child: _build(context));
  }

  Widget _build(BuildContext context) {
    const ph = ImagePlaceholder();
    if (ref.isEmpty) return ph;

    if (ref.startsWith('asset:')) {
      return Image.asset(
        'assets/images/${ref.substring(6)}.webp',
        fit: fit,
        errorBuilder: (_, __, ___) => ph,
      );
    }

    if (ref.startsWith('media:')) {
      final id = ref.substring(6);
      return ListenableBuilder(
        listenable: AppState.I,
        builder: (_, __) {
          final bytes = AppState.I.mediaFor(id);
          if (bytes == null) return const ImagePlaceholder(loading: true);
          return Image.memory(
            bytes,
            fit: fit,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => ph,
          );
        },
      );
    }

    if (ref.startsWith('data:')) {
      final bytes = _decodeCached(ref);
      if (bytes == null) return ph;
      return Image.memory(
        bytes,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => ph,
      );
    }

    var url = ref;
    if (cacheVersion.isNotEmpty) {
      url = '$url${url.contains('?') ? '&' : '?'}bosla_ad_v=$cacheVersion';
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) => const ImagePlaceholder(loading: true),
      errorWidget: (_, __, ___) {
        final s = AppState.I.settings;
        final path = Api.supaPathFromUrl(ref, s.supaUrl, s.supaBucket);
        if (path.isEmpty) return ph;
        return CachedNetworkImage(
          imageUrl: Api.supaAuthenticatedUrl(path, s.supaUrl, s.supaBucket),
          httpHeaders: Api.supaHeaders,
          fit: fit,
          placeholder: (_, __) => const ImagePlaceholder(loading: true),
          errorWidget: (_, __, ___) => ph,
        );
      },
    );
  }
}
