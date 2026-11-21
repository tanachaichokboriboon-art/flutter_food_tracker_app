import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_food_tracker_app/models/food.dart';
import 'package:flutter_food_tracker_app/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';

class AddFoodTrackerUi extends StatefulWidget {
  const AddFoodTrackerUi({super.key});

  @override
  State<AddFoodTrackerUi> createState() => _AddFoodTrackerUiState();
}

class _AddFoodTrackerUiState extends State<AddFoodTrackerUi> {
  // ----------- ส่วนของโค้ดที่เกี่ยวกับการเปิดกล้อง เปิดแกลอรี่ --------------

  Uint8List? imageBytes; // เอาไว้เก็บรูปเพื่อแสดงที่หน้าจอ
  XFile? imageFile; // เอาไว้เก็บรูปเพื่อที่จะ upload ไปยัง Supabase

  // เมธอดเปิดกล้อง
  Future<void> selectImageFromCamera() async {
    imageFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    // ตรวจสอบว่าได้ถ่ายรูปไหม
    if (imageFile != null) {
      final byte = await imageFile!.readAsBytes();

      setState(() {
        imageBytes = byte;
      });
    }
  }

  // เมธอดเปิดแกลอรี่
  Future<void> selectImageFromGallery() async {
    imageFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    // ตรวจสอบว่าได้เลือกรูปไหม
    if (imageFile != null) {
      final byte = await imageFile!.readAsBytes();

      setState(() {
        imageBytes = byte;
      });
    }
  }

  // เมนูเลือกระหว่างกล้องกับแกลอรี่
  void showImagePickerOption() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('ถ่ายรูปจากกล้อง'),
                onTap: () {
                  Navigator.pop(context);
                  selectImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('เลือกรูปจากแกลอรี่'),
                onTap: () {
                  Navigator.pop(context);
                  selectImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------------

  // ----------- ส่วนของโค้ดที่เกี่ยวกับการ upload และ save ข้อมูล -----------

  // ตัวแปรสำหรับเก็บตำแหน่งไฟล์ที่อัปโหลดไปยัง Supabase
  String imageURL = "";

  // สร้างตัวควบคุม TextField
  TextEditingController foodNameCtrl = TextEditingController();
  TextEditingController foodPriceCtrl = TextEditingController();
  TextEditingController foodPersonCtrl = TextEditingController();

  // ตัวแปรเก็บมื้ออาหาร
  String? selectedMeal = 'เช้า';

  // ตัวแปรเก็บวันที่รับประทานอาหาร
  DateTime? selectedDate;

  // เมธอดเลือกวันที่
  Future<void> selectFoodDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'เลือกวันที่รับประทานอาหาร',
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  // เมธอดแปลงวันที่เป็น String
  String formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // เมธอด upload และ save ข้อมูล
  Future<void> uploadAndSaveData() async {
    // ตรวจสอบว่าผู้ใช้ป้อนข้อมูลครบหรือยัง
    if (foodNameCtrl.text.isEmpty ||
        foodPriceCtrl.text.isEmpty ||
        foodPersonCtrl.text.isEmpty ||
        selectedMeal == null ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณากรอกข้อมูลให้ครบถ้วน',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      return;
    }

    // ตรวจสอบว่าราคาเป็นตัวเลขหรือไม่
    final price = double.tryParse(foodPriceCtrl.text);
    final person = int.tryParse(foodPersonCtrl.text);

    if (price == null || price < 0 || person == null || person <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณากรอกราคาและจำนวนคนให้ถูกต้อง',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      return;
    }

    try {
      // upload file แต่ต้องตรวจสอบก่อนว่ามีไฟล์ที่จะอัปโหลดไหม
      if (imageFile != null) {
        imageURL = await SupabaseService().uploadImageFile(imageFile!);
      }

      // แพ็คข้อมูลเพื่อส่งไปบันทึกลง table
      Food foodData = Food(
        foodDate: formatDate(selectedDate!),
        foodMeal: selectedMeal,
        foodName: foodNameCtrl.text,
        foodPrice: price,
        foodPerson: person,
        foodImageUrl: imageURL,
      );

      // ส่งข้อมูลไปบันทึกลง table
      await SupabaseService().insertFood(foodData);

      if (!mounted) return;

      // หลังจากบันทึกเสร็จแสดงข้อความแจ้ง
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'อัปโหลดและบันทึกข้อมูลเรียบร้อยแล้ว',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // ย้อนกลับไปหน้า ShowAllFoodTrackerUI()
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      // กรณีเกิดข้อผิดพลาด
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เกิดข้อผิดพลาด: $error',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ----------------------------------------------------------------

  @override
  void dispose() {
    foodNameCtrl.dispose();
    foodPriceCtrl.dispose();
    foodPersonCtrl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ส่วนของ AppBar
      appBar: AppBar(
        backgroundColor: const Color(0xFFF44336),
        title: const Text(
          'Food Tracker (เพิ่ม)',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
        ),
      ),

      // ส่วนของ Body
      body: Container(
        color: const Color(0xFFFFF7FF),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 64,
              bottom: 32,
              left: 28,
              right: 28,
            ),
            child: Center(
              child: Column(
                children: [
                  // ส่วนเลือกรูปอาหาร
                  InkWell(
                    onTap: showImagePickerOption,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.34,
                      height: MediaQuery.of(context).size.width * 0.34,
                      child: Center(
                        child: imageBytes == null
                            ? Icon(
                                Icons.camera_enhance,
                                size: MediaQuery.of(context).size.width * 0.24,
                                color: Colors.grey,
                              )
                            : Image.memory(
                                imageBytes!,
                                width: MediaQuery.of(context).size.width * 0.34,
                                height:
                                    MediaQuery.of(context).size.width * 0.34,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ช่องกรอกชื่ออาหาร
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'กินอะไร',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  TextField(
                    controller: foodNameCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      hintText: 'เช่น KFC, Pizza',
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // เลือกมื้ออาหาร
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'กินมื้อไหน',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: ['เช้า', 'กลางวัน', 'เย็น', 'ว่าง'].map((meal) {
                      return ChoiceChip(
                        label: Text(
                          meal,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: selectedMeal == meal,
                        selectedColor: const Color(0xFF4CAF50),
                        backgroundColor: Colors.grey,
                        showCheckmark: false,
                        elevation: 2,
                        pressElevation: 2,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        shape: const StadiumBorder(),
                        onSelected: (selected) {
                          setState(() {
                            selectedMeal = selected ? meal : null;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ช่องกรอกราคาอาหาร
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'กินไปเท่าไหร่',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  TextField(
                    controller: foodPriceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      hintText: 'เช่น 299.50',
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ช่องกรอกจำนวนคน
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'กินกันกี่คน',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  TextField(
                    controller: foodPersonCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      hintText: 'เช่น 3',
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // เลือกวันที่รับประทานอาหาร
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'กินไปวันไหน',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  InkWell(
                    onTap: () {
                      selectFoodDate();
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedDate == null
                                  ? 'เช่น 2020-01-31'
                                  : formatDate(selectedDate!),
                            ),
                          ),
                          const Icon(Icons.calendar_month, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ปุ่มบันทึกข้อมูล
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // เรียกใช้เมธอด uploadAndSaveData()
                        uploadAndSaveData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF038D31),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'บันทึกข้อมูล',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  // ปุ่มยกเลิก
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // เคลียร์หน้าจอให้เหมือนตอนเปิดเข้ามา
                        setState(() {
                          imageBytes = null;
                          imageFile = null;
                          imageURL = '';

                          foodNameCtrl.clear();
                          foodPriceCtrl.clear();
                          foodPersonCtrl.clear();

                          selectedMeal = null;
                          selectedDate = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF44336),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
