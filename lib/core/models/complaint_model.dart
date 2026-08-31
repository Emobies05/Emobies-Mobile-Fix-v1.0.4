class ComplaintModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String address;
  final String? landmark;
  final double? lat;
  final double? lng;
  final String deviceModel;
  final String issueDescription;
  final String? imeiNumber;
  final String status;
  final String? assignedSupervisorId;
  final String? assignedDeliveryBoyId;
  final String? assignedServiceCenterId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? pickupTime;
  final DateTime? dropTime;
  final DateTime? repairStartTime;
  final DateTime? repairCompleteTime;
  final DateTime? deliveryTime;
  final DateTime? completedTime;
  final double? estimatedCost;
  final double? finalCost;
  final bool isPaid;
  final String? paymentMethod;
  final String? transactionId;
  final List<String>? imagesBefore;
  final List<String>? imagesAfter;
  final List<String>? deliveryImages;
  final String? supervisorNotes;
  final String? serviceCenterNotes;
  final String? customerNotes;
  final String? ignoreReason;
  final bool isMonitored;
  final Map<String, dynamic>? metadata;

  ComplaintModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.address,
    this.landmark,
    this.lat,
    this.lng,
    required this.deviceModel,
    required this.issueDescription,
    this.imeiNumber,
    this.status = 'pending',
    this.assignedSupervisorId,
    this.assignedDeliveryBoyId,
    this.assignedServiceCenterId,
    required this.createdAt,
    this.updatedAt,
    this.pickupTime,
    this.dropTime,
    this.repairStartTime,
    this.repairCompleteTime,
    this.deliveryTime,
    this.completedTime,
    this.estimatedCost,
    this.finalCost,
    this.isPaid = false,
    this.paymentMethod,
    this.transactionId,
    this.imagesBefore,
    this.imagesAfter,
    this.deliveryImages,
    this.supervisorNotes,
    this.serviceCenterNotes,
    this.customerNotes,
    this.ignoreReason,
    this.isMonitored = true,
    this.metadata,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] ?? '',
      customerId: json['customer_id'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      customerEmail: json['customer_email'],
      address: json['address'] ?? '',
      landmark: json['landmark'],
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
      deviceModel: json['device_model'] ?? '',
      issueDescription: json['issue_description'] ?? '',
      imeiNumber: json['imei_number'],
      status: json['status'] ?? 'pending',
      assignedSupervisorId: json['assigned_supervisor_id'],
      assignedDeliveryBoyId: json['assigned_delivery_boy_id'],
      assignedServiceCenterId: json['assigned_service_center_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      pickupTime: json['pickup_time'] != null
          ? DateTime.parse(json['pickup_time'])
          : null,
      dropTime: json['drop_time'] != null
          ? DateTime.parse(json['drop_time'])
          : null,
      repairStartTime: json['repair_start_time'] != null
          ? DateTime.parse(json['repair_start_time'])
          : null,
      repairCompleteTime: json['repair_complete_time'] != null
          ? DateTime.parse(json['repair_complete_time'])
          : null,
      deliveryTime: json['delivery_time'] != null
          ? DateTime.parse(json['delivery_time'])
          : null,
      completedTime: json['completed_time'] != null
          ? DateTime.parse(json['completed_time'])
          : null,
      estimatedCost: json['estimated_cost']?.toDouble(),
      finalCost: json['final_cost']?.toDouble(),
      isPaid: json['is_paid'] ?? false,
      paymentMethod: json['payment_method'],
      transactionId: json['transaction_id'],
      imagesBefore: json['images_before'] != null
          ? List<String>.from(json['images_before'])
          : null,
      imagesAfter: json['images_after'] != null
          ? List<String>.from(json['images_after'])
          : null,
      deliveryImages: json['delivery_images'] != null
          ? List<String>.from(json['delivery_images'])
          : null,
      supervisorNotes: json['supervisor_notes'],
      serviceCenterNotes: json['service_center_notes'],
      customerNotes: json['customer_notes'],
      ignoreReason: json['ignore_reason'],
      isMonitored: json['is_monitored'] ?? true,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'customer_email': customerEmail,
    'address': address,
    'landmark': landmark,
    'lat': lat,
    'lng': lng,
    'device_model': deviceModel,
    'issue_description': issueDescription,
    'imei_number': imeiNumber,
    'status': status,
    'assigned_supervisor_id': assignedSupervisorId,
    'assigned_delivery_boy_id': assignedDeliveryBoyId,
    'assigned_service_center_id': assignedServiceCenterId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'pickup_time': pickupTime?.toIso8601String(),
    'drop_time': dropTime?.toIso8601String(),
    'repair_start_time': repairStartTime?.toIso8601String(),
    'repair_complete_time': repairCompleteTime?.toIso8601String(),
    'delivery_time': deliveryTime?.toIso8601String(),
    'completed_time': completedTime?.toIso8601String(),
    'estimated_cost': estimatedCost,
    'final_cost': finalCost,
    'is_paid': isPaid,
    'payment_method': paymentMethod,
    'transaction_id': transactionId,
    'images_before': imagesBefore,
    'images_after': imagesAfter,
    'delivery_images': deliveryImages,
    'supervisor_notes': supervisorNotes,
    'service_center_notes': serviceCenterNotes,
    'customer_notes': customerNotes,
    'ignore_reason': ignoreReason,
    'is_monitored': isMonitored,
    'metadata': metadata,
  };

  ComplaintModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? address,
    String? landmark,
    double? lat,
    double? lng,
    String? deviceModel,
    String? issueDescription,
    String? imeiNumber,
    String? status,
    String? assignedSupervisorId,
    String? assignedDeliveryBoyId,
    String? assignedServiceCenterId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? pickupTime,
    DateTime? dropTime,
    DateTime? repairStartTime,
    DateTime? repairCompleteTime,
    DateTime? deliveryTime,
    DateTime? completedTime,
    double? estimatedCost,
    double? finalCost,
    bool? isPaid,
    String? paymentMethod,
    String? transactionId,
    List<String>? imagesBefore,
    List<String>? imagesAfter,
    List<String>? deliveryImages,
    String? supervisorNotes,
    String? serviceCenterNotes,
    String? customerNotes,
    String? ignoreReason,
    bool? isMonitored,
    Map<String, dynamic>? metadata,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      address: address ?? this.address,
      landmark: landmark ?? this.landmark,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      deviceModel: deviceModel ?? this.deviceModel,
      issueDescription: issueDescription ?? this.issueDescription,
      imeiNumber: imeiNumber ?? this.imeiNumber,
      status: status ?? this.status,
      assignedSupervisorId: assignedSupervisorId ?? this.assignedSupervisorId,
      assignedDeliveryBoyId: assignedDeliveryBoyId ?? this.assignedDeliveryBoyId,
      assignedServiceCenterId: assignedServiceCenterId ?? this.assignedServiceCenterId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pickupTime: pickupTime ?? this.pickupTime,
      dropTime: dropTime ?? this.dropTime,
      repairStartTime: repairStartTime ?? this.repairStartTime,
      repairCompleteTime: repairCompleteTime ?? this.repairCompleteTime,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      completedTime: completedTime ?? this.completedTime,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      finalCost: finalCost ?? this.finalCost,
      isPaid: isPaid ?? this.isPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      imagesBefore: imagesBefore ?? this.imagesBefore,
      imagesAfter: imagesAfter ?? this.imagesAfter,
      deliveryImages: deliveryImages ?? this.deliveryImages,
      supervisorNotes: supervisorNotes ?? this.supervisorNotes,
      serviceCenterNotes: serviceCenterNotes ?? this.serviceCenterNotes,
      customerNotes: customerNotes ?? this.customerNotes,
      ignoreReason: ignoreReason ?? this.ignoreReason,
      isMonitored: isMonitored ?? this.isMonitored,
      metadata: metadata ?? this.metadata,
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'pending': return 'Pending';
      case 'accepted': return 'Accepted';
      case 'assigned': return 'Assigned';
      case 'pickup_ongoing': return 'Pickup Ongoing';
      case 'reached_customer': return 'Reached Customer';
      case 'phone_collected': return 'Phone Collected';
      case 'dropped_sc': return 'At Service Center';
      case 'repair_ongoing': return 'Repair Ongoing';
      case 'repair_completed': return 'Repair Done';
      case 'payment_pending': return 'Payment Pending';
      case 'paid': return 'Paid';
      case 'ready_for_delivery': return 'Ready for Delivery';
      case 'handover_delivery': return 'Handed to Delivery';
      case 'out_for_delivery': return 'Out for Delivery';
      case 'delivered': return 'Delivered';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  bool get canAccept => status == 'pending';
  bool get canIgnore => status == 'pending';
  bool get canCollect => status == 'reached_customer';
  bool get canDrop => status == 'phone_collected';
  bool get canStartRepair => status == 'dropped_sc' && isPaid;
  bool get canCompleteRepair => status == 'repair_ongoing';
  bool get canHandover => status == 'paid' || status == 'repair_completed';
}