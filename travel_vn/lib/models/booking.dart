class Booking {
  final int bookingId;
  final String? bookingCode;
  final String? memberId;
  final int destinationId;
  final String contactName;
  final String contactPhone;
  final DateTime visitDate;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final String? note;
  final DateTime createdAt;

  const Booking({
    required this.bookingId,
    this.bookingCode,
    this.memberId,
    required this.destinationId,
    required this.contactName,
    required this.contactPhone,
    required this.visitDate,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    double parseDouble(dynamic value) =>
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

    int parseInt(dynamic value) =>
        value is num ? value.toInt() : int.tryParse('$value') ?? 0;

    return Booking(
      bookingId: parseInt(json['bookingId']),
      bookingCode: json['bookingCode']?.toString(),
      memberId: json['memberId']?.toString(),
      destinationId: parseInt(json['destinationId']),
      contactName: json['contactName']?.toString() ?? '',
      contactPhone: json['contactPhone']?.toString() ?? '',
      visitDate: parseDate(json['visitDate']),
      unitPrice: parseDouble(json['unitPrice']),
      quantity: parseInt(json['quantity']),
      totalPrice: parseDouble(json['totalPrice']),
      paymentMethod: json['paymentMethod']?.toString() ?? 'Cash',
      paymentStatus: json['paymentStatus']?.toString() ?? 'Unpaid',
      status: json['status']?.toString() ?? 'Pending',
      note: json['note']?.toString(),
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'destinationId': destinationId,
        'contactName': contactName,
        'contactPhone': contactPhone,
        'visitDate': _dateOnly(visitDate),
        'unitPrice': unitPrice,
        'quantity': quantity,
        'totalPrice': totalPrice,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'status': status,
        'note': note,
        // Backend BookingRepository hiện INSERT trực tiếp @CreatedAt,
        // vì vậy cần gửi trường này dù SQL có DEFAULT.
        'createdAt': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toUpdateStatusJson() => {
        'bookingId': bookingId,
        'status': status,
      };

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Booking copyWith({String? status}) => Booking(
        bookingId: bookingId,
        bookingCode: bookingCode,
        memberId: memberId,
        destinationId: destinationId,
        contactName: contactName,
        contactPhone: contactPhone,
        visitDate: visitDate,
        unitPrice: unitPrice,
        quantity: quantity,
        totalPrice: totalPrice,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        status: status ?? this.status,
        note: note,
        createdAt: createdAt,
      );
}
