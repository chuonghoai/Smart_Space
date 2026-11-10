import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Tiện ích bóc tách và xóa sạch siêu dữ liệu (Metadata / EXIF / GPS / Timestamps)
/// của hình ảnh (JPEG, PNG, WebP) và video (MP4, MOV) trước khi lưu về thiết bị.
class MediaMetadataSanitizer {
  MediaMetadataSanitizer._();

  /// Làm sạch file và trả về dữ liệu [Uint8List] đã xóa toàn bộ metadata.
  static Future<Uint8List> sanitizeFile(File file) async {
    final bytes = await file.readAsBytes();
    final ext = file.path.split('.').last.toLowerCase();
    return sanitizeBytes(bytes, ext);
  }

  /// Làm sạch mảng byte dựa trên định dạng đuôi file [extension].
  static Uint8List sanitizeBytes(Uint8List bytes, String extension) {
    if (bytes.isEmpty) return bytes;
    final ext = extension.toLowerCase().replaceAll('.', '').trim();

    try {
      if (ext == 'jpg' || ext == 'jpeg') {
        return sanitizeJpeg(bytes);
      } else if (ext == 'png') {
        return sanitizePng(bytes);
      } else if (ext == 'webp') {
        return sanitizeWebp(bytes);
      } else if (ext == 'mp4' || ext == 'mov' || ext == 'm4v') {
        return sanitizeMp4(bytes);
      }
    } catch (e) {
      debugPrint('[MediaMetadataSanitizer] Error sanitizing .$ext: $e');
    }

    // Nếu không thuộc các định dạng trên hoặc gặp lỗi không xác định, trả về byte gốc
    return bytes;
  }

  /// Xóa toàn bộ EXIF, IPTC, XMP và Comment trong file JPEG/JPG.
  /// Bảo toàn 100% Huffman tables, Quantization tables và frame image data.
  static Uint8List sanitizeJpeg(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return bytes; // Không phải định dạng JPEG hợp lệ
    }

    final buffer = BytesBuilder();
    // Ghi SOI (Start of Image)
    buffer.addByte(0xFF);
    buffer.addByte(0xD8);

    int i = 2;
    while (i < bytes.length) {
      if (bytes[i] != 0xFF) {
        // Dữ liệu ngoài chuẩn, giữ nguyên
        buffer.addByte(bytes[i]);
        i++;
        continue;
      }

      // Bỏ qua các byte 0xFF đệm
      while (i < bytes.length && bytes[i] == 0xFF) {
        i++;
      }
      if (i >= bytes.length) break;

      final marker = bytes[i];
      i++;

      // EOI (End of Image)
      if (marker == 0xD9) {
        buffer.addByte(0xFF);
        buffer.addByte(0xD9);
        break;
      }

      // SOS (Start of Scan): Từ đây đến hết file là dữ liệu nén ảnh, không còn metadata
      if (marker == 0xDA) {
        buffer.addByte(0xFF);
        buffer.addByte(0xDA);
        buffer.add(bytes.sublist(i));
        break;
      }

      // Marker không có độ dài (RST0..RST7, SOI, TEM)
      if ((marker >= 0xD0 && marker <= 0xD7) || marker == 0x01) {
        buffer.addByte(0xFF);
        buffer.addByte(marker);
        continue;
      }

      // Các marker có length field
      if (i + 1 >= bytes.length) break;
      final length = (bytes[i] << 8) | bytes[i + 1];
      if (length < 2 || i + length > bytes.length) {
        // Dữ liệu lỗi cấu trúc length, giữ nguyên phần còn lại
        buffer.add(bytes.sublist(i - 2));
        break;
      }

      // Các marker chứa metadata cần xóa sạch:
      // 0xE1: APP1 (EXIF, GPS, Timestamps, Camera model, XMP)
      // 0xED: APP13 (Photoshop, IPTC metadata)
      // 0xFE: COM (Comments)
      // 0xE3..0xEF: Các APP marker phụ khác (ngoại trừ APP0 JFIF và APP2 ICC)
      final isMetadataMarker = marker == 0xE1 ||
          marker == 0xED ||
          marker == 0xFE ||
          (marker >= 0xE3 && marker <= 0xEF);

      if (!isMetadataMarker) {
        // Giữ lại marker và nội dung của nó (như DQT, DHT, SOF0, APP0 JFIF)
        buffer.addByte(0xFF);
        buffer.addByte(marker);
        buffer.add(bytes.sublist(i, i + length));
      }

      i += length;
    }

    return buffer.toBytes();
  }

  /// Xóa toàn bộ chunk metadata trong file PNG (eXIf, tIME, tEXt, zTXt, iTXt).
  static Uint8List sanitizePng(Uint8List bytes) {
    // 8-byte PNG signature: 137 80 78 71 13 10 26 10
    const pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    if (bytes.length < 8) return bytes;
    for (int k = 0; k < 8; k++) {
      if (bytes[k] != pngSignature[k]) return bytes;
    }

    final buffer = BytesBuilder();
    buffer.add(pngSignature);

    // Danh sách chunk metadata cần xóa
    const metadataChunks = {'eXIf', 'tIME', 'tEXt', 'zTXt', 'iTXt'};

    int offset = 8;
    while (offset + 8 <= bytes.length) {
      final length = (bytes[offset] << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3];

      final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
      final totalChunkSize = 12 + length; // 4 len + 4 type + data + 4 crc

      if (offset + totalChunkSize > bytes.length) {
        // Chunk bị cụt, copy nốt phần còn lại
        buffer.add(bytes.sublist(offset));
        break;
      }

      if (!metadataChunks.contains(type)) {
        buffer.add(bytes.sublist(offset, offset + totalChunkSize));
      }

      offset += totalChunkSize;
      if (type == 'IEND') break;
    }

    return buffer.toBytes();
  }

  /// Xóa metadata EXIF và XMP trong file WebP (thay chunk type thành JUNK padding).
  static Uint8List sanitizeWebp(Uint8List bytes) {
    if (bytes.length < 12) return bytes;
    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    final webp = String.fromCharCodes(bytes.sublist(8, 12));
    if (riff != 'RIFF' || webp != 'WEBP') return bytes;

    final output = Uint8List.fromList(bytes);
    int offset = 12;

    while (offset + 8 <= output.length) {
      final fourCC = String.fromCharCodes(output.sublist(offset, offset + 4));
      final size = output[offset + 4] |
          (output[offset + 5] << 8) |
          (output[offset + 6] << 16) |
          (output[offset + 7] << 24);

      if (fourCC == 'EXIF' || fourCC == 'XMP ') {
        // Đổi fourCC thành 'JUNK' và điền byte 0 vào payload
        output[offset] = 0x4A;     // 'J'
        output[offset + 1] = 0x55; // 'U'
        output[offset + 2] = 0x4E; // 'N'
        output[offset + 3] = 0x4B; // 'K'
        final payloadStart = offset + 8;
        final payloadEnd = (payloadStart + size).clamp(0, output.length);
        for (int p = payloadStart; p < payloadEnd; p++) {
          output[p] = 0;
        }
      }

      // WebP chunks are padded to even size
      final paddedSize = size + (size % 2);
      offset += 8 + paddedSize;
    }

    return output;
  }

  /// Làm sạch file video MP4 / MOV / M4V:
  /// 1. Reset creation_time & modification_time trong mvhd, tkhd, mdhd về 0.
  /// 2. Chuyển đổi box 'udta' (User Data) và 'meta' thành box 'free' và zero payload
  ///    để xóa sạch tọa độ GPS (©xyz), camera/device model, author tags
  ///    mà không làm thay đổi độ dài byte hoặc phá vỡ bảng chunk offset stco/co64.
  static Uint8List sanitizeMp4(Uint8List bytes) {
    if (bytes.length < 8) return bytes;
    final output = Uint8List.fromList(bytes);

    int offset = 0;
    while (offset + 8 <= output.length) {
      final size = (output[offset] << 24) |
          (output[offset + 1] << 16) |
          (output[offset + 2] << 8) |
          output[offset + 3];

      final type = String.fromCharCodes(output.sublist(offset + 4, offset + 8));

      int actualSize = size;
      int headerSize = 8;
      if (size == 1 && offset + 16 <= output.length) {
        // 64-bit size
        headerSize = 16;
        actualSize = (output[offset + 8] << 56) |
            (output[offset + 9] << 48) |
            (output[offset + 10] << 40) |
            (output[offset + 11] << 32) |
            (output[offset + 12] << 24) |
            (output[offset + 13] << 16) |
            (output[offset + 14] << 8) |
            output[offset + 15];
      } else if (size == 0) {
        actualSize = output.length - offset;
      }

      if (actualSize < headerSize || offset + actualSize > output.length) break;

      if (type == 'moov') {
        _sanitizeMoovBox(output, offset + headerSize, offset + actualSize);
      }

      offset += actualSize;
    }

    return output;
  }

  static void _sanitizeMoovBox(Uint8List data, int start, int end) {
    int offset = start;
    while (offset + 8 <= end) {
      final size = (data[offset] << 24) |
          (data[offset + 1] << 16) |
          (data[offset + 2] << 8) |
          data[offset + 3];

      final type = String.fromCharCodes(data.sublist(offset + 4, offset + 8));
      if (size < 8 || offset + size > end) break;

      if (type == 'mvhd') {
        // Movie Header Box: reset creation & modification times
        final version = data[offset + 8];
        if (version == 0 && offset + 20 <= end) {
          // creation_time (offset 12..15), mod_time (offset 16..19)
          for (int i = 12; i < 20; i++) {
            data[offset + i] = 0;
          }
        } else if (version == 1 && offset + 28 <= end) {
          // 64-bit creation_time (12..19), mod_time (20..27)
          for (int i = 12; i < 28; i++) {
            data[offset + i] = 0;
          }
        }
      } else if (type == 'trak') {
        // Track box: recursively sanitize tkhd, mdia
        _sanitizeTrakBox(data, offset + 8, offset + size);
      } else if (type == 'udta' || type == 'meta') {
        // User Data / Metadata box chứa GPS (©xyz), camera tags, software:
        // Đổi FourCC sang 'free' và zero payload
        data[offset + 4] = 0x66; // 'f'
        data[offset + 5] = 0x72; // 'r'
        data[offset + 6] = 0x65; // 'e'
        data[offset + 7] = 0x65; // 'e'
        for (int p = offset + 8; p < offset + size; p++) {
          data[p] = 0;
        }
      }

      offset += size;
    }
  }

  static void _sanitizeTrakBox(Uint8List data, int start, int end) {
    int offset = start;
    while (offset + 8 <= end) {
      final size = (data[offset] << 24) |
          (data[offset + 1] << 16) |
          (data[offset + 2] << 8) |
          data[offset + 3];

      final type = String.fromCharCodes(data.sublist(offset + 4, offset + 8));
      if (size < 8 || offset + size > end) break;

      if (type == 'tkhd') {
        // Track Header: reset creation & modification times
        final version = data[offset + 8];
        if (version == 0 && offset + 20 <= end) {
          for (int i = 12; i < 20; i++) {
            data[offset + i] = 0;
          }
        } else if (version == 1 && offset + 28 <= end) {
          for (int i = 12; i < 28; i++) {
            data[offset + i] = 0;
          }
        }
      } else if (type == 'mdia') {
        _sanitizeMdiaBox(data, offset + 8, offset + size);
      } else if (type == 'udta') {
        data[offset + 4] = 0x66; // 'f'
        data[offset + 5] = 0x72; // 'r'
        data[offset + 6] = 0x65; // 'e'
        data[offset + 7] = 0x65; // 'e'
        for (int p = offset + 8; p < offset + size; p++) {
          data[p] = 0;
        }
      }

      offset += size;
    }
  }

  static void _sanitizeMdiaBox(Uint8List data, int start, int end) {
    int offset = start;
    while (offset + 8 <= end) {
      final size = (data[offset] << 24) |
          (data[offset + 1] << 16) |
          (data[offset + 2] << 8) |
          data[offset + 3];

      final type = String.fromCharCodes(data.sublist(offset + 4, offset + 8));
      if (size < 8 || offset + size > end) break;

      if (type == 'mdhd') {
        // Media Header: reset creation & modification times
        final version = data[offset + 8];
        if (version == 0 && offset + 20 <= end) {
          for (int i = 12; i < 20; i++) {
            data[offset + i] = 0;
          }
        } else if (version == 1 && offset + 28 <= end) {
          for (int i = 12; i < 28; i++) {
            data[offset + i] = 0;
          }
        }
      }

      offset += size;
    }
  }
}
