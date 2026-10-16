class SuperAdminCorporateCustomersResponse {
  final bool success;
  final List<SuperAdminCorporateClient> clients;

  SuperAdminCorporateCustomersResponse({
    required this.success,
    required this.clients,
  });

  factory SuperAdminCorporateCustomersResponse.fromJson(Map<String, dynamic> json) {
    return SuperAdminCorporateCustomersResponse(
      success: json['success'] ?? false,
      clients: (json['clients'] as List?)
              ?.map((c) => SuperAdminCorporateClient.fromJson(c))
              .toList() ??
          [],
    );
  }
}

class SuperAdminCorporateClient {
  final String id;
  final String companyName;
  final String contactPerson;
  final String email;
  final String phone;
  final double balance;
  final int pendingInvoices;
  final bool isActive;
  final String logo;

  SuperAdminCorporateClient({
    required this.id,
    required this.companyName,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.balance,
    required this.pendingInvoices,
    required this.isActive,
    required this.logo,
  });

  factory SuperAdminCorporateClient.fromJson(Map<String, dynamic> json) {
    return SuperAdminCorporateClient(
      id: json['id']?.toString() ?? '',
      companyName: json['companyName'] ?? 'Unknown',
      contactPerson: json['contactPerson'] ?? 'N/A',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      pendingInvoices: json['pendingInvoices'] ?? 0,
      isActive: json['isActive'] ?? false,
      logo: json['logo'] ?? 'C',
    );
  }
}
