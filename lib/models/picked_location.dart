/// Ubicación simplificada: por ahora solo texto libre (ciudad/dirección).
/// Se deja el modelo listo para que, cuando agregues Google Maps más
/// adelante, solo tengas que llenar [latitude]/[longitude] sin tocar el
/// resto del código (los servicios y modelos ya aceptan esos campos).
class PickedLocation {
  final double? latitude;
  final double? longitude;
  final String label;

  PickedLocation({this.latitude, this.longitude, required this.label});
}
