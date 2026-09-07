import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/picked_location.dart';

/// Onboarding obligatorio por pasos, distinto según el rol:
///  Adoptante: Foto -> Datos personales -> Ubicación (mapa) -> Vivienda.
///  Refugio:   Foto/Logo -> Datos de la organización -> Ubicación (mapa).
/// No se puede usar el resto de la app hasta completarlo.
class ProfileSetupScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onComplete;

  const ProfileSetupScreen({super.key, required this.profile, required this.onComplete});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _pageController = PageController();
  final _firestore = FirestoreService();
  final _storage = StorageService();

  int _step = 0;
  bool _saving = false;

  // Foto obligatoria.
  XFile? _photoFile;

  // Datos personales / organización.
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _orgDescCtrl = TextEditingController();
  final _legalIdCtrl = TextEditingController();

  // Ubicación (por ahora texto libre; el mapa se agrega más adelante).
  final _locationCtrl = TextEditingController();

  // Vivienda (solo adoptante).
  HousingType _housing = HousingType.apartment;
  bool _hasChildren = false;
  bool _hasOtherPets = false;

  bool get _isAdopter => widget.profile.role == UserRole.adopter;
  int get _totalSteps => _isAdopter ? 4 : 3;

  @override
  void dispose() {
    _pageController.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _orgDescCtrl.dispose();
    _legalIdCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0 && _photoFile == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('La foto de perfil es obligatoria para continuar.')));
      return;
    }
    if (_step == 2 && _locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Escribe tu ciudad o dirección para continuar.')));
      return;
    }
    if (_step < _totalSteps - 1) {
      setState(() => _step += 1);
      _pageController.animateToPage(_step, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step -= 1);
    _pageController.animateToPage(_step, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final photoUrl = await _storage.uploadProfilePhoto(_photoFile!, widget.profile.uid);

      final data = <String, dynamic>{
        'photoUrl': photoUrl,
        'phone': _phoneCtrl.text.trim(),
        'latitude': null,
        'longitude': null,
        'addressLabel': _locationCtrl.text.trim(),
        'onboardingComplete': true,
      };

      if (_isAdopter) {
        data.addAll({
          'housingType': _housing.value,
          'hasChildren': _hasChildren,
          'hasOtherPets': _hasOtherPets,
          'bio': _bioCtrl.text.trim(),
        });
      } else {
        data.addAll({
          'organizationName': widget.profile.name,
          'organizationDescription': _orgDescCtrl.text.trim(),
          'legalIdOrRuc': _legalIdCtrl.text.trim(),
        });
      }

      await _firestore.updateProfile(widget.profile.uid, data);
      widget.onComplete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: List.generate(_totalSteps, (i) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 5,
                decoration: BoxDecoration(
                  color: i <= _step ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: _isAdopter
                    ? [_photoStep(), _adopterDataStep(), _locationStep(), _housingStep()]
                    : [_photoStep(), _shelterDataStep(), _locationStep()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _back,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Atrás'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: LoadingButton(
                      loading: _saving,
                      label: _step == _totalSteps - 1 ? 'Finalizar' : 'Continuar',
                      onPressed: _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepScaffold({required String title, required String subtitle, required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 13.5)),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }

  Widget _photoStep() {
    return _stepScaffold(
      title: _isAdopter ? 'Tu foto de perfil' : 'Logo o foto del refugio',
      subtitle: 'Es obligatoria: ayuda a generar confianza entre adoptantes y refugios.',
      child: Center(
        child: ProfilePhotoPicker(
          localFile: _photoFile,
          networkUrl: widget.profile.photoUrl,
          onPicked: (f) => setState(() => _photoFile = f),
        ),
      ),
    );
  }

  Widget _adopterDataStep() {
    return _stepScaffold(
      title: 'Cuéntanos de ti',
      subtitle: 'Esta información la verán los refugios al evaluar tu solicitud.',
      child: Column(
        children: [
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: fieldDecoration('Teléfono de contacto', Icons.phone_outlined),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _bioCtrl,
            maxLines: 4,
            decoration: fieldDecoration('Cuéntanos por qué quieres adoptar', Icons.notes_rounded),
          ),
        ],
      ),
    );
  }

  Widget _shelterDataStep() {
    return _stepScaffold(
      title: 'Datos de tu organización',
      subtitle: 'Esto genera confianza en los adoptantes que revisen tus publicaciones.',
      child: Column(
        children: [
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: fieldDecoration('Teléfono de contacto', Icons.phone_outlined),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _legalIdCtrl,
            decoration: fieldDecoration('RUC / Registro legal (opcional)', Icons.badge_outlined),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _orgDescCtrl,
            maxLines: 4,
            decoration: fieldDecoration('Describe tu refugio o labor de rescate', Icons.notes_rounded),
          ),
        ],
      ),
    );
  }

  Widget _locationStep() {
    return _stepScaffold(
      title: 'Tu ubicación',
      subtitle: 'Escribe tu ciudad o dirección. Más adelante se puede activar la selección en mapa (Google Maps).',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _locationCtrl,
            decoration: fieldDecoration('Ciudad / dirección (ej. Cayambe, Pichincha)', Icons.place_outlined),
          ),
        ],
      ),
    );
  }

  Widget _housingStep() {
    return _stepScaffold(
      title: 'Compatibilidad habitacional',
      subtitle: 'Ayuda a los refugios a encontrar la mascota ideal para tu hogar.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tipo de vivienda', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _OptionChip(
                  icon: HousingType.apartment.icon,
                  label: HousingType.apartment.label,
                  selected: _housing == HousingType.apartment,
                  onTap: () => setState(() => _housing = HousingType.apartment),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OptionChip(
                  icon: HousingType.house.icon,
                  label: HousingType.house.label,
                  selected: _housing == HousingType.house,
                  onTap: () => setState(() => _housing = HousingType.house),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('¿Hay niños en el hogar?', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _OptionChip(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Sí',
                      selected: _hasChildren,
                      onTap: () => setState(() => _hasChildren = true))),
              const SizedBox(width: 12),
              Expanded(
                  child: _OptionChip(
                      icon: Icons.remove_circle_outline_rounded,
                      label: 'No',
                      selected: !_hasChildren,
                      onTap: () => setState(() => _hasChildren = false))),
            ],
          ),
          const SizedBox(height: 18),
          const Text('¿Tienes otras mascotas?', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _OptionChip(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Sí',
                      selected: _hasOtherPets,
                      onTap: () => setState(() => _hasOtherPets = true))),
              const SizedBox(width: 12),
              Expanded(
                  child: _OptionChip(
                      icon: Icons.remove_circle_outline_rounded,
                      label: 'No',
                      selected: !_hasOtherPets,
                      onTap: () => setState(() => _hasOtherPets = false))),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : AppColors.textLight),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13, color: selected ? Colors.white : AppColors.textDark)),
          ],
        ),
      ),
    );
  }
}
