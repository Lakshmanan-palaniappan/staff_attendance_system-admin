import 'package:flutter/material.dart';
import '../services/admin_api.dart';

class StaffAttendancePage extends StatefulWidget {
  final int? preSelectedStaffId;
  final String? preSelectedName;
  final String? preSelectedVersion;

  const StaffAttendancePage({
    super.key,
    this.preSelectedStaffId,
    this.preSelectedName,
    this.preSelectedVersion,
  });

  @override
  State<StaffAttendancePage> createState() => _StaffAttendancePageState();
}

class _StaffAttendancePageState extends State<StaffAttendancePage> {
  List<dynamic> staffList = [];
  List<dynamic> pairs = [];
  List<dynamic> fullAttendance = [];

  bool loadingStaff = true;
  bool loadingFull = false;
  bool loadingPairs = false;

  int? selectedStaffId;
  String selectedStaffName = "";
  String selectedStaffVersion = "-";

  @override
  void initState() {
    super.initState();
    _loadStaffList();

    if (widget.preSelectedStaffId != null) {
      selectedStaffId = widget.preSelectedStaffId!;
      selectedStaffName = widget.preSelectedName ?? "User";
      selectedStaffVersion = widget.preSelectedVersion ?? "-";
      _loadPairs(selectedStaffId!);
      _loadFullAttendance(selectedStaffId!);
    }
  }

  Future<void> _loadStaffList() async {
    try {
      staffList = await AdminApi.getAllStaffs();
    } catch (e) {
      debugPrint("Staff list error: $e");
    }
    setState(() => loadingStaff = false);
  }

  Future<void> _loadFullAttendance(int id) async {
    setState(() {
      loadingFull = true;
      selectedStaffId = id;
    });

    try {
      fullAttendance = await AdminApi.getStaffAttendance(id);
    } catch (e) {
      debugPrint("Full Attendance error: $e");
    }

    setState(() => loadingFull = false);
  }

  Future<void> _loadPairs(int id) async {
    setState(() => loadingPairs = true);

    try {
      pairs = await AdminApi.getCheckPairs(id);
    } catch (e) {
      debugPrint("Pairs Error: $e");
    }

    setState(() => loadingPairs = false);
  }

  String fmt(dynamic t) {
    if (t == null) return "—";
    try {
      final dt = DateTime.parse(t.toString());
      return "${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return t.toString();
    }
  }

  // ------------------- STAFF SELECTOR --------------------
  void _openStaffSelector() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select Staff"),
        content: SizedBox(
          height: 300,
          child: loadingStaff
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: staffList.length,
                  itemBuilder: (_, i) {
                    final s = staffList[i];
                    final staffId =
                        int.tryParse(s["StaffId"].toString()) ?? 0;
                    final staffName = (s["StaffName"] ??
                            s["Username"] ??
                            s["EmpUName"] ??
                            "User")
                        .toString();
                    final appVersion = (s["AppVersion"] ?? "-").toString();

                    return ListTile(
                      title: Text(staffName),
                      subtitle: Text(
                          "User: ${s["Username"] ?? s["EmpUName"] ?? ""}"),
                      onTap: () {
                        Navigator.pop(context);
                        selectedStaffName = staffName;
                        selectedStaffVersion = appVersion;
                        selectedStaffId = staffId;
                        _loadPairs(staffId);
                        _loadFullAttendance(staffId);
                        setState(() {});
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  // --------------------------- UI -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Overview"),
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_account),
            onPressed: _openStaffSelector,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedStaffId != null) ...[
              Text(
                "$selectedStaffName — Work Hours",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 4),
                child: Text(
                  "App Version: $selectedStaffVersion",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "Select a staff to view work hours and full attendance.",
                  style: TextStyle(fontSize: 16),
                ),
              ),

            const SizedBox(height: 10),

            // Two minimized, internally scrollable containers
            Expanded(
              child: Column(
                children: [
                  // Work Hours
                  Expanded(
                    child: _workHoursCard(),
                  ),
                  const SizedBox(height: 12),
                  // Full Attendance
                  Expanded(
                    child: _fullAttendanceCard(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- WORK HOURS CARD ----------------------
  Widget _workHoursCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: loadingPairs
            ? const Center(child: CircularProgressIndicator())
            : selectedStaffId == null
                ? const Center(
                    child: Text("Select a staff to see work hours"),
                  )
                : pairs.isEmpty
                    ? const Center(
                        child: Text("No work hours recorded"),
                      )
                    : Scrollbar(
                        child: SingleChildScrollView(
                          child: _pairsList(),
                        ),
                      ),
      ),
    );
  }

  // ---------------- FULL ATTENDANCE CARD ----------------------
  Widget _fullAttendanceCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: loadingFull
            ? const Center(child: CircularProgressIndicator())
            : selectedStaffId == null
                ? const Center(
                    child: Text("Select a staff to see full attendance"),
                  )
                : fullAttendance.isEmpty
                    ? const Center(
                        child: Text("No attendance records found"),
                      )
                    : Scrollbar(
                        child: SingleChildScrollView(
                          child: _fullAttendanceList(),
                        ),
                      ),
      ),
    );
  }

  // ---------------- WORK HOURS CONTENT ----------------------
  Widget _pairsList() {
    if (pairs.isEmpty) {
      return const Text("No work hours recorded");
    }

    // Group by date
    Map<String, List<dynamic>> grouped = {};
    for (var row in pairs) {
      String date = row["Date"] ?? "--";
      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(row);
    }

    Duration grandTotal = Duration.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        String date = entry.key;
        List<dynamic> logs = entry.value;

        Duration dailyTotal = Duration.zero;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Chip(
                label: Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.indigo.shade50,
              ),
            ),
            ...logs.map((row) {
              final checkIn = row["CheckInTime"] != null
                  ? DateTime.parse(row["CheckInTime"])
                  : null;

              final checkOut = row["CheckOutTime"] != null
                  ? DateTime.parse(row["CheckOutTime"])
                  : null;

              Duration diff = Duration.zero;

              if (checkIn != null && checkOut != null) {
                diff = checkOut.difference(checkIn);
                dailyTotal += diff;
                grandTotal += diff;
              }

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text("Check-in: ${fmt(row["CheckInTime"])}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Check-out: ${fmt(row["CheckOutTime"])}"),
                      const SizedBox(height: 4),
                      Text(
                        "Worked: ${diff.inHours}h ${diff.inMinutes % 60}m",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                "Total: ${dailyTotal.inHours}h ${dailyTotal.inMinutes % 60}m",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const Divider(height: 20),
          ],
        );
      }).toList(),
    );
  }

  // ---------------- FULL ATTENDANCE CONTENT ----------------------
  Widget _fullAttendanceList() {
    return Column(
      children: fullAttendance.map((row) {
        return Card(
          child: ListTile(
            leading: Icon(
              row["CheckType"] == "checkin" ? Icons.login : Icons.logout,
              color:
                  row["CheckType"] == "checkin" ? Colors.green : Colors.red,
            ),
            title: Text(row["CheckType"].toUpperCase()),
            subtitle: Text(fmt(row["Timestamp"])),
          ),
        );
      }).toList(),
    );
  }
}
