class Food {
  //ตัวแปรตั้งชื่อล้อกับชื่อคอลัมน์ในตาราง
  String? id;
  String? created_at;
  String? foodDate;
  String? foodMeal;
  String? foodName;
  double? foodPrice;
  int? foodPerson;
  String? foodImageUrl;

  //Constructor เอาไว้แพ็กข้อมูลเพื่อส่งไปบันทึกลง table ของ Supabase
  Food({
    this.id,
    this.created_at,
    this.foodDate,
    this.foodMeal,
    this.foodName,
    this.foodPrice,
    this.foodPerson,
    this.foodImageUrl,
  });

  //การแปลงข้อมูลฝั่ง mobile เป็น JSON เพื่อส่งไปยัง Supabase : toJson
  Map<String, dynamic> toJson() => {
        "foodDate": foodDate,
        "foodMeal": foodMeal,
        "foodName": foodName,
        "foodPrice": foodPrice,
        "foodPerson": foodPerson,
        "foodImageUrl": foodImageUrl,
      };

  //การแปลงข้อมูลฝั่ง Supabase มาใช้ในฝั่ง mobile : fromJson
  factory Food.fromJson(Map<String, dynamic> json) => Food(
        id: json["id"] as String?,
        created_at: json["created_at"] as String?,
        foodDate: json["foodDate"] as String?,
        foodMeal: json["foodMeal"] as String?,
        foodName: json["foodName"] as String?,
        foodPrice: (json["foodPrice"] as num?)?.toDouble(),
        foodPerson: json["foodPerson"] as int?,
        foodImageUrl: json["foodImageUrl"] as String?,
      );
}
