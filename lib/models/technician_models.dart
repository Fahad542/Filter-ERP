import 'package:flutter/material.dart';
import 'technician_assigned_orders_model.dart';
import 'technician_order_details_model.dart';

class TechOrder {
  final String id; // This will be the orderId for display
  final String jobId;
  final String customerName;
  final String vehicleModel;
  final String plateNumber;
  final String department;
  final double totalValue;
  final double commission;
  final String status; // 'Pending', 'In Progress', 'Completed'
  final String assignmentStatus;
  final String? customerMobile;
  final String? serviceType;
  final String? arrivalTime;
  final String? completedAt;
  final DateTime? timestamp;
  final List<TechOrderDepartment> departments;

  TechOrder({
    required this.id,
    required this.jobId,
    required this.customerName,
    required this.vehicleModel,
    required this.plateNumber,
    required this.department,
    required this.totalValue,
    required this.commission,
    required this.status,
    required this.assignmentStatus,
    this.customerMobile,
    this.serviceType,
    this.arrivalTime,
    this.completedAt,
    this.timestamp,
    this.departments = const [],
  });

  factory TechOrder.fromAssignedOrder(AssignedOrder order) {
    return TechOrder(
      id: order.orderId,
      jobId: order.jobId,
      customerName: order.customerName,
      vehicleModel: order.vehicle,
      plateNumber: order.plateNo,
      department: order.department,
      totalValue: order.value,
      commission: order.commission,
      status: order.status,
      assignmentStatus: order.assignmentStatus,
      timestamp: DateTime.tryParse(order.completedAt)?.toLocal() ??
          DateTime.tryParse(order.submittedAt)?.toLocal() ??
          DateTime.tryParse(order.orderDateTime)?.toLocal(),
    );
  }

  factory TechOrder.fromOrderDetails(OrderDetailsData data) {
    return TechOrder(
      id: data.orderId,
      jobId: data.jobId,
      customerName: data.customerName,
      customerMobile: data.customerMobile,
      vehicleModel: data.vehicle,
      plateNumber: data.plateNo,
      department: data.department,
      serviceType: data.serviceType,
      arrivalTime: data.arrivalTime,
      totalValue: data.value,
      commission: data.commission,
      status: data.status,
      assignmentStatus: 'assigned', // It's assigned if we have details
      completedAt: data.completedAt,
      timestamp: DateTime.now(),
      departments: data.departments,
    );
  }
}

class CommissionRecord {
  final String id;
  final String orderId;
  final DateTime date;
  final double amount;
  final String status; // 'Paid', 'Pending'

  CommissionRecord({
    required this.id,
    required this.orderId,
    required this.date,
    required this.amount,
    required this.status,
  });
}

class TechNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'Broadcast', 'Assignment', 'Commission'

  TechNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
  });
}
