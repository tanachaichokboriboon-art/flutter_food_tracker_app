import 'package:flutter/material.dart';
import 'package:flutter_food_tracker_app/models/food.dart';
import 'package:flutter_food_tracker_app/services/supabase_service.dart';
import 'package:flutter_food_tracker_app/views/add_food_tracker_ui.dart';
import 'package:flutter_food_tracker_app/views/update_delete_food_tracker_ui.dart';

class ShowAllFoodTrackerUI extends StatefulWidget {
  const ShowAllFoodTrackerUI({super.key});

  @override
  State<ShowAllFoodTrackerUI> createState() => _ShowAllFoodTrackerUIState();
}

class _ShowAllFoodTrackerUIState extends State<ShowAllFoodTrackerUI> {
  List<Food>? foodData;
  String? _loadError;
  bool _isLoading = true;

  Future<void> fetchFoodData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final data = await SupabaseService().getAllFoods();
      if (!mounted) return;
      setState(() {
        foodData = data;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchFoodData();
  }

  Future<void> _openAddFood() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const AddFoodTrackerUi(),
      ),
    );
    if (mounted) fetchFoodData();
  }

  Future<void> _openFood(Food food) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => UpdateDeleteFoodTrackerUi(foodDataDetail: food),
      ),
    );
    if (mounted) fetchFoodData();
  }

  Widget _foodImage(Food food) {
    final imageUrl = food.foodImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.asset(
        'assets/images/logo.png',
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      imageUrl,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/images/logo.png',
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _foodList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'โหลดข้อมูลไม่สำเร็จ\n$_loadError',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: fetchFoodData,
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }
    if (foodData == null || foodData!.isEmpty) {
      return const Center(child: Text('ยังไม่มีข้อมูลอาหาร'));
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: foodData!.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final food = foodData![index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Material(
            color: index.isEven
                ? const Color(0xFFE6F4E8)
                : const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              onTap: () => _openFood(food),
              tileColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: _foodImage(food),
              ),
              title: Text(
                'กิน: ${food.foodName ?? ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, color: Colors.black),
              ),
              subtitle: Text(
                'วันที่: ${food.foodDate ?? ''} มื้อ: ${food.foodMeal ?? ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF555555),
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Color(0xFFF44336),
                size: 35,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = MediaQuery.sizeOf(context).width * 0.40;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF44336),
        title: const Text(
          'Food Tracker',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddFood,
        backgroundColor: const Color(0xFFF44336),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add, size: 36),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Container(
        color: const Color(0xFFFFF7FF),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).width * 0.10),
            Image.asset(
              'assets/images/logo.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
            ),
            SizedBox(height: MediaQuery.sizeOf(context).width * 0.065),
            Expanded(child: _foodList()),
          ],
        ),
      ),
    );
  }
}
