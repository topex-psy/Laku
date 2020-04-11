extension StringExtension on String {

  /// fungsi untuk mencaritahu apakah string kosong atau null
  bool get isEmptyOrNull => (this ?? '').isEmpty;

  /// fungsi untuk menghapus karakter selain angka, lalu cast ke integer
  int get nominal {
    try {
      return isEmptyOrNull ? 0 : int.parse(this.replaceAll(RegExp(r'\D+'), ''));
    } catch(e) {
      print("'$this' ($e)");
      return 0;
    }
  }

  /// fungsi untuk memeriksa validitas email
  bool get isValidEmail => !this.isEmptyOrNull && RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$").hasMatch(this);

  /// fungsi truncate teks ke panjang maksimum dengan penambahan ellipsis
  String truncate(int maxlength) => this.length > maxlength ? this.substring(0, maxlength) + "..." : this;

}