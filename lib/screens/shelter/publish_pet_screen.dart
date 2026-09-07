import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

/// Formulario para publicar una mascota nueva, o para editar una ya
/// existente si se pasa [existingPet] (reutiliza toda la misma UI y
/// validaciones; solo cambia si se hace `publishPet` o `updatePet`).
class PublishPetScreen extends StatefulWidget {
  final Pet? existingPet;

  const PublishPetScreen({super.key, this.existingPet});

  bool get isEditing => existingPet != null;

  @override
  State<PublishPetScreen> createState() => _PublishPetScreenState();
}

class _PublishPetScreenState extends State<PublishPetScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.existingPet?.name);
  late final _ageCtrl = TextEditingController(text: widget.existingPet?.age);
  late final _breedCtrl = TextEditingController(text: widget.existingPet?.breed);
  late final _descCtrl = TextEditingController(text: widget.existingPet?.description);
  late final _locationCtrl = TextEditingController(text: widget.existingPet?.addressLabel);
  final _firestore = FirestoreService();
  final _storage = StorageService();

  String? _species;
  HousingType _housing = HousingType.apartment;
  XFile? _mainPhoto;
  XFile? _vaccineFile;
  bool _saving = false;

  late Map<String, bool> _checklist;

  final Map<String, IconData> _checklistIcons = const {
    'Vacuna Antirrábica': Icons.vaccines_rounded,
    'Triple Felina/Canina': Icons.medical_services_rounded,
    'Desparasitación al día': Icons.bug_report_rounded,
    'Esterilizado': Icons.healing_rounded,
  };

  final _speciesOptions = const ['Perro', 'Gato', 'Otro'];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingPet;
    _checklist = {
      'Vacuna Antirrábica': existing?.healthChecklist['Vacuna Antirrábica'] ?? false,
      'Triple Felina/Canina': existing?.healthChecklist['Triple Felina/Canina'] ?? false,
      'Desparasitación al día': existing?.healthChecklist['Desparasitación al día'] ?? false,
      'Esterilizado': existing?.healthChecklist['Esterilizado'] ?? false,
    };
    if (existing != null) {
      _species = existing.species;
      _housing = existing.housingTag.toLowerCase().contains('depart') ? HousingType.apartment : HousingType.house;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _breedCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.existingPet;

    // La foto y el carnet solo son obligatorios al publicar por primera
    // vez; al editar, si no se elige uno nuevo, se conserva el existente.
    if (existing == null && _mainPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agrega una foto principal real de la mascota')));
      return;
    }
    if (existing == null && _vaccineFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sube el carnet de vacunación (foto o PDF)')));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    setState(() => _saving = true);
    try {
      final photoUrl = _mainPhoto != null ? await _storage.uploadPetPhoto(_mainPhoto!, uid) : existing?.imageUrl;
      final vaccineUrl =
          _vaccineFile != null ? await _storage.uploadVaccineDocument(_vaccineFile!, uid) : existing?.vaccineCardUrl;

      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'species': _species ?? 'Otro',
        'age': _ageCtrl.text.trim(),
        'breed': _breedCtrl.text.trim().isEmpty ? (_species ?? '') : _breedCtrl.text.trim(),
        'addressLabel': _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        'imageUrl': photoUrl,
        'housingTag': _housing == HousingType.apartment ? 'Apto para Departamento' : 'Requiere Espacio Amplio',
        'description': _descCtrl.text.trim(),
        'vaccineCardUrl': vaccineUrl,
        'healthChecklist': _checklist,
      };

      if (existing != null) {
        await _firestore.updatePet(existing.id, data);
      } else {
        final profile = await _firestore.getProfile(uid);
        data.addAll({
          'shelterId': uid,
          'shelterName': profile?.organizationName ?? profile?.name ?? 'Refugio',
          'active': true,
        });
        final pet = Pet.fromMap('', data);
        await _firestore.publishPet(pet);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existing != null ? '${_nameCtrl.text.trim()} se actualizó correctamente' : '${_nameCtrl.text.trim()} fue publicado exitosamente'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
        if (existing != null) {
          Navigator.of(context).pop();
        } else {
          setState(() {
            _nameCtrl.clear();
            _ageCtrl.clear();
            _breedCtrl.clear();
            _descCtrl.clear();
            _species = null;
            _mainPhoto = null;
            _vaccineFile = null;
            _locationCtrl.clear();
            _checklist.updateAll((key, value) => false);
          });
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.shelterBg,
      appBar: AppBar(
        backgroundColor: AppColors.shelterBg,
        foregroundColor: AppColors.shelterText,
        elevation: 0,
        title: Text(widget.isEditing ? 'Editar Mascota' : 'Publicar Mascota'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Información básica'),
              _lightField(_nameCtrl, 'Nombre de la mascota', Icons.badge_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null),
              const SizedBox(height: 14),
              _lightDropdown(),
              const SizedBox(height: 14),
              _lightField(_ageCtrl, 'Edad (años o meses)', Icons.cake_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null),
              const SizedBox(height: 14),
              _lightField(_breedCtrl, 'Raza', Icons.pets_rounded),
              const SizedBox(height: 14),
              _lightField(_descCtrl, 'Descripción breve', Icons.notes_rounded, maxLines: 3),
              const SizedBox(height: 22),
              _sectionTitle('Vivienda recomendada'),
              Row(
                children: [
                  Expanded(child: _HousingChip(label: 'Departamento', selected: _housing == HousingType.apartment, onTap: () => setState(() => _housing = HousingType.apartment))),
                  const SizedBox(width: 12),
                  Expanded(child: _HousingChip(label: 'Casa con patio', selected: _housing == HousingType.house, onTap: () => setState(() => _housing = HousingType.house))),
                ],
              ),
              const SizedBox(height: 22),
              _sectionTitle('Ubicación de la mascota'),
              _lightField(_locationCtrl, 'Ciudad / dirección (opcional)', Icons.place_outlined),
              const SizedBox(height: 22),
              _sectionTitle('Trazabilidad médica y fotografías'),
              MediaUploadField(
                label: 'Foto Principal',
                icon: Icons.add_photo_alternate_outlined,
                localFile: _mainPhoto,
                networkUrl: widget.existingPet?.imageUrl,
                onPicked: (f) => setState(() => _mainPhoto = f),
              ),
              const SizedBox(height: 14),
              MediaUploadField(
                label: 'Carnet de Vacunación (foto o PDF)',
                icon: Icons.description_outlined,
                localFile: _vaccineFile,
                networkUrl: widget.existingPet?.vaccineCardUrl,
                allowPdf: true,
                onPicked: (f) => setState(() => _vaccineFile = f),
              ),
              const SizedBox(height: 18),
              _sectionTitle('Checklist sanitario'),
              Text(
                'Marca lo que ya esté al día; el adoptante lo verá reflejado en el carnet digital.',
                style: TextStyle(color: AppColors.shelterTextMuted, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: _checklist.keys.map((key) {
                    final isLast = key == _checklist.keys.last;
                    final checked = _checklist[key] ?? false;
                    return Container(
                      decoration: BoxDecoration(
                        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
                      ),
                      child: CheckboxListTile(
                        value: checked,
                        onChanged: (v) => setState(() => _checklist[key] = v ?? false),
                        title: Text(
                          key,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        subtitle: Text(
                          checked ? 'Marcado como al día' : 'Aún pendiente',
                          style: TextStyle(fontSize: 11.5, color: checked ? AppColors.primaryDark : AppColors.textLight),
                        ),
                        secondary: Icon(_checklistIcons[key] ?? Icons.check_circle_outline_rounded,
                            color: checked ? AppColors.primary : AppColors.textLight),
                        activeColor: AppColors.primary,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              LoadingButton(loading: _saving, label: widget.isEditing ? 'Guardar Cambios' : 'Publicar Mascota', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: const TextStyle(color: AppColors.shelterAccent, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.3)),
      );

  Widget _lightField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1, String? Function(String?)? validator}) {
    // Se usa una etiqueta fija arriba (en vez de labelText flotante) para
    // evitar que el texto de la etiqueta quede superpuesto con el borde
    // del campo cuando ya trae un valor precargado (pantalla de editar).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label, style: const TextStyle(color: AppColors.shelterTextMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textDark),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textLight, size: 20),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.6)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.danger)),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _lightDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text('Especie', style: TextStyle(color: AppColors.shelterTextMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
        DropdownButtonFormField<String>(
          initialValue: _species,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.pets_rounded, color: AppColors.textLight, size: 20),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.6)),
          ),
          items: _speciesOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _species = v),
          validator: (v) => v == null ? 'Selecciona una especie' : null,
        ),
      ],
    );
  }
}

class _HousingChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _HousingChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.shelterAccent : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.shelterAccent : AppColors.border),
        ),
        child: Text(label, style: TextStyle(color: selected ? AppColors.shelterBg : AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }
}
