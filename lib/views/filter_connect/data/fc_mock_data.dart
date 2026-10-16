/// Demo data aligned with filter-connect-ai.lovable.app content.
class KpiItem {
  const KpiItem({
    required this.label,
    required this.value,
    required this.delta,
    this.hint,
  });
  final String label;
  final String value;
  final String delta;
  final String? hint;
}

class InsightItem {
  const InsightItem({
    required this.tag,
    required this.title,
    required this.body,
    required this.colorTag,
  });
  final String tag;
  final String title;
  final String body;
  final String colorTag; // hurdle | churn | forecast | franchise
}

class BranchTarget {
  const BranchTarget({
    required this.name,
    required this.pct,
    required this.actual,
    required this.target,
    required this.staff,
  });
  final String name;
  final int pct;
  final String actual;
  final String target;
  final int staff;
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.assignee,
    required this.branch,
    required this.due,
    required this.priority,
    required this.status,
    required this.spent,
    required this.budget,
    this.overBudget = false,
    this.noBudget = false,
  });
  final String id;
  final String title;
  final String assignee;
  final String branch;
  final String due;
  final String priority;
  final String status;
  final String spent;
  final String budget;
  final bool overBudget;
  final bool noBudget;
}

class ExpenseItem {
  const ExpenseItem({
    required this.id,
    required this.title,
    required this.category,
    required this.person,
    required this.when,
    required this.taskId,
    required this.taskTitle,
    required this.amount,
    required this.status,
    this.aboveLimit = false,
  });
  final String id;
  final String title;
  final String category;
  final String person;
  final String when;
  final String taskId;
  final String taskTitle;
  final String amount;
  final String status;
  final bool aboveLimit;
}

class ChatThread {
  const ChatThread({
    required this.name,
    required this.preview,
    required this.time,
    this.unread = 0,
    this.isGroup = true,
  });
  final String name;
  final String preview;
  final String time;
  final int unread;
  final bool isGroup;
}

class ChatMessage {
  const ChatMessage({
    required this.author,
    required this.body,
    required this.time,
    this.isMe = false,
    this.hasAttachment = false,
    this.attachmentName,
  });
  final String author;
  final String body;
  final String time;
  final bool isMe;
  final bool hasAttachment;
  final String? attachmentName;
}

class CustomerRow {
  const CustomerRow({
    required this.name,
    required this.type,
    required this.vehicles,
    required this.ltv,
    required this.lastVisit,
    required this.segment,
    required this.churn,
  });
  final String name;
  final String type;
  final int vehicles;
  final String ltv;
  final String lastVisit;
  final String segment;
  final int churn;
}

abstract final class MockData {
  static const kpis = [
    KpiItem(
      label: 'Month sales',
      value: 'SAR 616,900',
      delta: '+6.4%',
      hint: 'Forecast SAR 1.02M',
    ),
    KpiItem(
      label: 'Budget vs actual',
      value: '93%',
      delta: '+2.1%',
      hint: 'SAR 102,300 of SAR 111,000',
    ),
    KpiItem(
      label: 'Pending approvals',
      value: '2',
      delta: '1 above AI limit',
    ),
    KpiItem(
      label: 'Tasks on time',
      value: '86%',
      delta: '+4.8%',
      hint: '1 task over budget',
    ),
  ];

  static const insights = [
    InsightItem(
      tag: 'Target Hurdle',
      title: 'Malaz branch at 52% by mid-month',
      body:
          'Average ticket size dropped 18% and 9 bookings were cancelled. Suggest pushing the brake + filter combo offer and re-assigning 2 technicians to bay 1.',
      colorTag: 'hurdle',
    ),
    InsightItem(
      tag: 'Churn Prediction',
      title: '23 customers at high risk of not returning',
      body:
          'All are 90+ days overdue on service. AI drafted a win-back SMS with a 15% filter-change offer — ready for approval.',
      colorTag: 'churn',
    ),
    InsightItem(
      tag: 'Sales Forecast',
      title: 'Month is trending to SAR 1.02M (+6.4%)',
      body:
          'Thursday remains the strongest day. Adding one evening bay shift at Olaya could add ~SAR 38K this month.',
      colorTag: 'forecast',
    ),
    InsightItem(
      tag: 'Franchise Intelligence',
      title: 'Bilal Rauf is 2 franchises behind target',
      body:
          'Zero signings in 45 days with 1 weak pipeline lead. Recommend pairing with Sara Al Harbi and re-routing 3 warm Dammam leads.',
      colorTag: 'franchise',
    ),
  ];

  static const branches = [
    BranchTarget(
      name: 'Olaya',
      pct: 77,
      actual: 'SAR 231,400',
      target: 'SAR 300,000',
      staff: 14,
    ),
    BranchTarget(
      name: 'Malaz',
      pct: 52,
      actual: 'SAR 129,500',
      target: 'SAR 250,000',
      staff: 11,
    ),
    BranchTarget(
      name: 'Dammam',
      pct: 87,
      actual: 'SAR 156,800',
      target: 'SAR 180,000',
      staff: 9,
    ),
    BranchTarget(
      name: 'Jeddah North',
      pct: 45,
      actual: 'SAR 98,200',
      target: 'SAR 220,000',
      staff: 12,
    ),
  ];

  static const tasks = [
    TaskItem(
      id: 'TSK-1042',
      title: 'Corporate fleet oil service — Al Rajhi (12 vehicles)',
      assignee: 'Ahmed Naseer',
      branch: 'Olaya',
      due: '2026-08-18',
      priority: 'High',
      status: 'In Progress',
      spent: 'SAR 9,250',
      budget: 'SAR 14,500',
    ),
    TaskItem(
      id: 'TSK-1039',
      title: 'Outdoor pickup — brake pads purchase (Batha market)',
      assignee: 'Khalid Omar',
      branch: 'Malaz',
      due: '2026-08-15',
      priority: 'High',
      status: 'Over Budget',
      spent: 'SAR 3,640',
      budget: 'SAR 3,200',
      overBudget: true,
    ),
    TaskItem(
      id: 'TSK-1036',
      title: 'Franchise onboarding visit — Dammam prospect',
      assignee: 'Sara Al Harbi',
      branch: 'HQ Sales',
      due: '2026-08-20',
      priority: 'Medium',
      status: 'Pending',
      spent: 'SAR 1,150',
      budget: 'SAR 5,000',
    ),
    TaskItem(
      id: 'TSK-1031',
      title: 'Follow up 18 lapsed customers (90+ days)',
      assignee: 'Noura Fahad',
      branch: 'Olaya',
      due: '2026-08-16',
      priority: 'Medium',
      status: 'In Progress',
      spent: '—',
      budget: '—',
      noBudget: true,
    ),
  ];

  static const expenses = [
    ExpenseItem(
      id: 'EXP-7781',
      title: 'Extra brake pad set — supplier price increase',
      category: 'Spare Parts',
      person: 'Khalid Omar',
      when: 'Today · 11:24',
      taskId: 'TSK-1039',
      taskTitle: 'Outdoor pickup — brake pads purchase',
      amount: 'SAR 640',
      status: 'Pending AI Q&A',
    ),
    ExpenseItem(
      id: 'EXP-7779',
      title: 'Fleet pickup and delivery runs, 3 trips',
      category: 'Fuel & Transport',
      person: 'Ahmed Naseer',
      when: 'Today · 09:02',
      taskId: 'TSK-1042',
      taskTitle: 'Corporate fleet oil service — Al Rajhi',
      amount: 'SAR 380',
      status: 'Approved by AI',
    ),
    ExpenseItem(
      id: 'EXP-7776',
      title: 'Tyre balancing machine deposit',
      category: 'Equipment',
      person: 'Sara Al Harbi',
      when: 'Yesterday · 17:40',
      taskId: 'TSK-1036',
      taskTitle: 'Franchise onboarding visit — Dammam',
      amount: 'SAR 8,600',
      status: 'Pending Human Approval',
      aboveLimit: true,
    ),
  ];

  static const chats = [
    ChatThread(
      name: 'Olaya Branch — Operations',
      preview: 'Ahmed: Fleet job 8 of 12 done ✅',
      time: '11:32',
      unread: 3,
    ),
    ChatThread(
      name: 'Accounts & Invoices',
      preview: 'Fatima: Please attach the Batha invoice here',
      time: '11:04',
      unread: 1,
    ),
    ChatThread(
      name: 'Khalid Omar',
      preview: 'Voice message · 0:24',
      time: '10:47',
      isGroup: false,
    ),
    ChatThread(
      name: 'Franchise Expansion',
      preview: 'Sara: Dammam prospect signed the LOI',
      time: '09:58',
    ),
  ];

  static const messages = [
    ChatMessage(
      author: 'Fatima Saleh',
      body:
          'Team, all outdoor purchases from today must be uploaded here before 6 PM. No WhatsApp.',
      time: '10:58',
    ),
    ChatMessage(
      author: 'Khalid Omar',
      body: 'Brake pads cost went up by 640 SAR at Batha. Submitting the expense now.',
      time: '11:02',
    ),
    ChatMessage(
      author: 'Khalid Omar',
      body: 'Invoice attached',
      time: '11:03',
      hasAttachment: true,
      attachmentName: 'invoice-batha-4471.jpg',
    ),
    ChatMessage(
      author: 'You',
      body: 'Link it to TSK-1039 so budget vs actual updates automatically.',
      time: '11:06',
      isMe: true,
    ),
    ChatMessage(
      author: 'Ahmed Naseer',
      body: 'Fleet job 8 of 12 done ✅ Remaining 4 vehicles tomorrow morning.',
      time: '11:32',
    ),
  ];

  static const customers = [
    CustomerRow(
      name: 'Al Rajhi Logistics',
      type: 'Corporate',
      vehicles: 42,
      ltv: 'SAR 268,400',
      lastVisit: '2 days ago',
      segment: 'Loyal',
      churn: 8,
    ),
    CustomerRow(
      name: 'Faisal Al Otaibi',
      type: 'Retail',
      vehicles: 2,
      ltv: 'SAR 12,400',
      lastVisit: '3 months ago',
      segment: 'Churn Risk',
      churn: 82,
    ),
    CustomerRow(
      name: 'Hala Rent A Car',
      type: 'Corporate',
      vehicles: 60,
      ltv: 'SAR 402,300',
      lastVisit: 'Yesterday',
      segment: 'Loyal',
      churn: 6,
    ),
    CustomerRow(
      name: 'Mishal Al Dosari',
      type: 'Retail',
      vehicles: 3,
      ltv: 'SAR 18,900',
      lastVisit: '5 months ago',
      segment: 'Lost',
      churn: 94,
    ),
  ];

  /// Last 7 days sales (k SAR) — actual vs AI forecast.
  static const salesDays = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  static const salesActual = [42.0, 38.0, 34.0, 44.0, 52.0, 56.0, 40.0];
  static const salesForecast = [40.0, 39.0, 36.0, 43.0, 50.0, 54.0, 42.0];

  /// Budget vs actual by category (k SAR).
  static const budgetCategories = [
    'Parts',
    'Transport',
    'Equipment',
    'Consumables',
    'Marketing',
  ];
  static const budgetValues = [42.0, 12.0, 30.0, 9.0, 18.0];
  static const budgetActual = [39.0, 14.0, 22.0, 8.0, 20.0];
}