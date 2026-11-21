import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_food_tracker_app/models/food.dart';
import 'package:flutter_food_tracker_app/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';

class UpdateDeleteFoodTrackerUi extends StatefulWidget {
  const UpdateDeleteFoodTrackerUi({
    super.key,
    required this.foodDataDetail,
  });

  final Food foodDataDetail;

  @override
  State<UpdateDeleteFoodTrackerUi> createState() =>
      _UpdateDeleteFoodTrackerUiState();
}

class _UpdateDeleteFoodTrackerUiState extends State<UpdateDeleteFoodTrackerUi> {
  static const _backgroundColor = Color(0xFFFFF7FF);
  static const _primaryColor = Color(0xFFF44336);
  static const _successColor = Color(0xFF4CAF50);
  static const _meals = ['เช้า', 'กลางวัน', 'เย็น', 'ว่าง'];

  final _foodNameCtrl = TextEditingController();
  final _foodPriceCtrl = TextEditingController();
  final _foodPersonCtrl = TextEditingController();

  Uint8List? _imageBytes;
  XFile? _imageFile;
  String? _imageUrl;
  String? _selectedMeal;
  DateTime? _selectedDate;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isBusy => _isSaving || _isDeleting;

  @override
  void initState() {
    super.initState();
    final food = widget.foodDataDetail;
    _foodNameCtrl.text = food.foodName ?? '';
    _foodPriceCtrl.text = food.foodPrice?.toString() ?? '';
    _foodPersonCtrl.text = food.foodPerson?.toString() ?? '';
    _imageUrl = food.foodImageUrl;
    _selectedMeal = food.foodMeal;
    _selectedDate = DateTime.tryParse(food.foodDate ?? '');
  }

  @override
  void dispose() {
    _foodNameCtrl.dispose();
    _foodPriceCtrl.dispose();
    _foodPersonCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _primaryColor : _successColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageFile = image;
        _imageBytes = bytes;
      });
    } catch (error) {
      if (mounted) _showMessage('เลือกรูปไม่สำเร็จ: $error', isError: true);
    }
  }

  Future<void> _showImagePickerOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ถ่ายรูปจากกล้อง'),
              onTap: () {
                Navigator.pop(context);
                _selectImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('เลือกรูปจากแกลอรี่'),
              onTap: () {
                Navigator.pop(context);
                _selectImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFoodDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'เลือกวันที่รับประทานอาหาร',
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _saveFood() async {
    final name = _foodNameCtrl.text.trim();
    final price = double.tryParse(_foodPriceCtrl.text.trim());
    final person = int.tryParse(_foodPersonCtrl.text.trim());

    if (name.isEmpty ||
        _selectedMeal == null ||
        _selectedDate == null ||
        price == null ||
        person == null) {
      _showMessage('กรุณากรอกข้อมูลให้ครบถ้วนและถูกต้อง', isError: true);
      return;
    }
    if (price < 0 || person <= 0) {
      _showMessage('กรุณากรอกราคาและจำนวนคนให้ถูกต้อง', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    String? newImageUrl;
    try {
      var imageUrl = _imageUrl ?? '';
      if (_imageFile != null) {
        newImageUrl = await SupabaseService().uploadImageFile(_imageFile!);
        imageUrl = newImageUrl;
      }

      final updatedFood = Food(
        foodDate: _formatDate(_selectedDate!),
        foodMeal: _selectedMeal,
        foodName: name,
        foodPrice: price,
        foodPerson: person,
        foodImageUrl: imageUrl,
      );
      await SupabaseService()
          .updateFood(updatedFood, widget.foodDataDetail.id!);

      if (newImageUrl != null && _imageUrl != null && _imageUrl!.isNotEmpty) {
        try {
          await SupabaseService().deleteImageFile(_storageFileName(_imageUrl!));
        } catch (_) {
          if (!mounted) return;
          _showMessage('บันทึกข้อมูลแล้ว แต่ลบรูปเดิมไม่สำเร็จ', isError: true);
          Navigator.pop(context);
          return;
        }
      }

      if (!mounted) return;
      _showMessage('บันทึกแก้ไขข้อมูลเรียบร้อยแล้ว');
      Navigator.pop(context);
    } catch (error) {
      if (newImageUrl != null) {
        try {
          await SupabaseService()
              .deleteImageFile(_storageFileName(newImageUrl));
        } catch (_) {
          // Keep the original save error visible; a failed upload cleanup is secondary.
        }
      }
      if (mounted) _showMessage('บันทึกข้อมูลไม่สำเร็จ: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _storageFileName(String url) {
    final segments = Uri.parse(url).pathSegments;
    if (segments.isEmpty) {
      throw FormatException('ไม่พบชื่อไฟล์รูปภาพใน URL');
    }
    return segments.last;
  }

  Future<void> _deleteFood() async {
    setState(() => _isDeleting = true);
    try {
      await SupabaseService().deleteFood(widget.foodDataDetail.id!);
      if (!mounted) return;

      final imageUrl = _imageUrl;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await SupabaseService().deleteImageFile(_storageFileName(imageUrl));
        } catch (error) {
          if (!mounted) return;
          _showMessage('ลบข้อมูลแล้ว แต่ลบรูปไม่สำเร็จ: $error', isError: true);
          Navigator.pop(context);
          return;
        }
      }

      if (!mounted) return;
      _showMessage('ลบข้อมูลเสร็จสิ้น');
      Navigator.pop(context);
    } catch (error) {
      if (mounted) _showMessage('ลบข้อมูลไม่สำเร็จ: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Widget _sectionLabel(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      );

  InputDecoration _inputDecoration() => InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      );

  @override
  Widget build(BuildContext context) {
    final imageSize = MediaQuery.sizeOf(context).width * 0.32;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text(
          'Food Tracker (แก้ไข/ลบ)',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: _isBusy ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
      ),
      body: Container(
        color: _backgroundColor,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 48, 28, 40),
            child: Column(
              children: [
                InkWell(
                  onTap: _isBusy ? null : _showImagePickerOptions,
                  child: _imageBytes != null
                      ? Image.memory(
                          _imageBytes!,
                          width: imageSize,
                          height: imageSize,
                          fit: BoxFit.cover,
                        )
                      : (_imageUrl == null || _imageUrl!.isEmpty)
                          ? Container(
                              width: imageSize,
                              height: imageSize,
                              color: Colors.black12,
                              child: const Icon(
                                Icons.add_a_photo,
                                size: 48,
                                color: Colors.grey,
                              ),
                            )
                          : Image.network(
                              _imageUrl!,
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: imageSize,
                                height: imageSize,
                                color: Colors.black12,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                ),
                const SizedBox(height: 28),
                _sectionLabel('กินอะไร'),
                TextField(
                  controller: _foodNameCtrl,
                  enabled: !_isBusy,
                  decoration: _inputDecoration(),
                ),
                const SizedBox(height: 24),
                _sectionLabel('กินมื้อไหน'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _meals.map((meal) {
                    final selected = _selectedMeal == meal;
                    return ChoiceChip(
                      label: Text(
                        meal,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      selected: selected,
                      showCheckmark: false,
                      selectedColor: _successColor,
                      backgroundColor: Colors.grey,
                      onSelected: _isBusy
                          ? null
                          : (value) => setState(
                                () => _selectedMeal = value ? meal : null,
                              ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      shape: const StadiumBorder(),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                _sectionLabel('กินไปเท่าไหร่'),
                TextField(
                  controller: _foodPriceCtrl,
                  enabled: !_isBusy,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration(),
                ),
                const SizedBox(height: 24),
                _sectionLabel('กินกันกี่คน'),
                TextField(
                  controller: _foodPersonCtrl,
                  enabled: !_isBusy,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(),
                ),
                const SizedBox(height: 24),
                _sectionLabel('กินไปวันไหน'),
                InkWell(
                  onTap: _isBusy ? null : _selectFoodDate,
                  child: InputDecorator(
                    decoration: _inputDecoration(),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDate == null
                                ? 'เลือกวันที่'
                                : _formatDate(_selectedDate!),
                          ),
                        ),
                        const Icon(Icons.calendar_month, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _saveFood,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _successColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('บันทึกแก้ไข'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _deleteFood,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isDeleting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ลบข้อมูล'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
