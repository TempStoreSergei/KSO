
import 'package:motel/domain/models/booking_models.dart';

class Room {
  final String roomNumber;
  final String bedNumber;
  final String buildingId;
  final RoomType type;

  Room({
    required this.roomNumber,
    required this.bedNumber,
    required this.buildingId,
    required this.type,
  });

  String get id => '$roomNumber-$bedNumber';
  String get name => '$roomNumber-$bedNumber';
}
