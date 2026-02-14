import 'dart:io';
import 'package:image/image.dart';

void main() async {
  final path = 'assets/icon/app_icon.png';
  final file = File(path);
  
  if (!await file.exists()) {
    print('Error: File not found at $path');
    exit(1);
  }

  final bytes = await file.readAsBytes();
  final image = decodePng(bytes);

  if (image == null) {
    print('Error: Could not decode image');
    exit(1);
  }

  print('Original size: ${image.width}x${image.height}');

  // Find bounding box
  int minX = image.width;
  int minY = image.height;
  int maxX = 0;
  int maxY = 0;

  // Threshold for "white". 255 is pure white.
  // We'll consider anything very bright as background.
  // But wait, the icon might have white parts inside.
  // We should scan from edges inwards.
  // Actually, iterating all pixels is safer to find the content extent.
  // Assuming the background is uniform white (255, 255, 255).
  
  bool hasContent = false;

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final r = pixel.r;
      final g = pixel.g;
      final b = pixel.b;
      final a = pixel.a;

      // Check if pixel is NOT white
      // Allow some tolerance for compression artifacts
      if (a > 0 && (r < 250 || g < 250 || b < 250)) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
        hasContent = true;
      }
    }
  }

  if (!hasContent) {
    print('Error: No content found (image appears all white)');
    exit(1);
  }

  // Add a small padding
  final padding = 0; // No padding as requested to "fill"
  minX = (minX - padding).clamp(0, image.width);
  minY = (minY - padding).clamp(0, image.height);
  maxX = (maxX + padding).clamp(0, image.width - 1);
  maxY = (maxY + padding).clamp(0, image.height - 1);

  final contentWidth = maxX - minX + 1;
  final contentHeight = maxY - minY + 1;

  print('Content bounding box: ($minX, $minY) - ($maxX, $maxY)');
  print('Content size: ${contentWidth}x${contentHeight}');

  // Crop
  final cropped = copyCrop(image, x: minX, y: minY, width: contentWidth, height: contentHeight);

  // Resize to 1024x1024 (standard app icon size)
  // We want to fill the square.
  // Since the icon might not be perfectly square, we'll resize the largest dimension to 1024
  // and center it on a 1024x1024 canvas?
  // Or just stretch? Stretching is bad.
  // The user said "fill the canvas", implying the white border was the problem.
  // If the content is roughly square (like a squircle), we can resize it to 1024x1024.
  
  final targetSize = 1024;
  final resized = copyResize(cropped, width: targetSize, height: targetSize, interpolation: Interpolation.cubic);

  // Save
  await file.writeAsBytes(encodePng(resized));
  print('Processed image saved to $path');
}
