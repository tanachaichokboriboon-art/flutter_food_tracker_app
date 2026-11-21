// ไฟล์นี้จะประกอบด้วยโค้ดคำสั่งการทำงานต่างๆ กับ Supabase
// เช่น อัปโหลดไฟล์, เพิ่ม ลบ แก้ไข ค้นหา/ตรวจสอบ/ดึง/ดู ข้อมูลในตาราง

import 'package:flutter_food_tracker_app/models/food.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class SupabaseService {
  static const _foodBucket = 'All access food_tracker_bk';

  // สร้าง instance/object/ตัวแทน ที่จะทำงานกับ Supabase
  final supabase = Supabase.instance.client;

  // เมธอดอัปโหลดไฟล์ไปยัง bucket ที่อยู่ใน storage ของ Supabase
  Future<String> uploadImageFile(XFile xfile) async {
    final extension = xfile.name.contains('.')
        ? xfile.name.split('.').last.toLowerCase()
        : 'jpg';
    final safeExtension =
        RegExp(r'^[a-z0-9]{1,10}$').hasMatch(extension) ? extension : 'jpg';
    final newFileName =
        '${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

    // upload ไฟล์
    await supabase.storage.from(_foodBucket).uploadBinary(
          newFileName,
          await xfile.readAsBytes(),
          fileOptions: FileOptions(contentType: xfile.mimeType),
        );

    // คืนค่า URL ของไฟล์ที่อัปโหลด
    return supabase.storage.from(_foodBucket).getPublicUrl(newFileName);
  }

  // เมธอดเพิ่มข้อมูลลง table ของ Supabase
  Future<void> insertFood(Food food) async {
    await supabase.from('food_tracker_tb').insert(food.toJson());
  }

  // เมธอดดึงข้อมูลทั้งหมดจาก table ของ Supabase
  Future<List<Food>> getAllFoods() async {
    final response = await supabase.from('food_tracker_tb').select('*');

    return response.map((e) => Food.fromJson(e)).toList();
  }

  // เมธอดลบไฟล์จาก bucket ของ Supabase
  Future<void> deleteImageFile(String fileName) async {
    await supabase.storage.from(_foodBucket).remove([fileName]);
  }

  // เมธอดแก้ไขข้อมูลใน table ของ Supabase
  Future<void> updateFood(Food food, String id) async {
    await supabase.from('food_tracker_tb').update(food.toJson()).eq('id', id);
  }

  // เมธอดลบข้อมูลออกจาก table ของ Supabase
  Future<void> deleteFood(String id) async {
    await supabase.from('food_tracker_tb').delete().eq('id', id);
  }
}
