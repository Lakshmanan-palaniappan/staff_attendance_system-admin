import 'package:flutter/material.dart';
import '../services/admin_api.dart';
import '../widgets/gradient_header.dart';
import 'staff_attendance_page.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  List<dynamic> requests = [];
  List<dynamic> staffs = [];
  bool loadingRequests = true;
  bool loadingStaffs = true;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    await Future.wait([
      _loadRequests(),
      _loadStaffs(),
    ]);
  }

  Future<void> _loadRequests() async {
    setState(() => loadingRequests = true);
    try {
      requests = await AdminApi.getPendingRequests();
    } catch (e) {
      debugPrint("Requests Error: $e");
    }
    setState(() => loadingRequests = false);
  }

  Future<void> _loadStaffs() async {
    setState(() => loadingStaffs = true);
    try {
      staffs = await AdminApi.getAllStaffs();
    } catch (e) {
      debugPrint("Staff Error: $e");
    }
    setState(() => loadingStaffs = false);
  }

  Future<void> _approve(int reqId, int staffId) async {
    try {
      await AdminApi.approveRequest(reqId, staffId);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Approved successfully")));
      _fetchAll();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  String _format(dynamic t) {
    if (t == null) return "—";
    try {
      final dt = DateTime.parse(t.toString());
      return "${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return t.toString();
    }
  }

  // ------------------- BUTTON: Open Today Attendance Page ------------------
  void _openTodayAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StaffAttendancePage(
          preSelectedStaffId: null,
          preSelectedName: null,
        ),
      ),
    );
  }

  // ------------------- STAFF HISTORY: Open per-staff attendance ------------------
  void _openAttendancePage(int staffId, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StaffAttendancePage(preSelectedStaffId: staffId, preSelectedName: name),
      ),
    );
  }

  // ------------------------------ UI ------------------------------
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.today),
        label: const Text("Today's Attendance"),
        backgroundColor: Colors.indigo,
        onPressed: _openTodayAttendance,
      ),

      body: Column(
        children: [
          const GradientHeader(title: "Admin Dashboard"),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchAll,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _requestsCard()),
                          const SizedBox(width: 20),
                          Expanded(flex: 3, child: _staffCard()),
                        ],
                      )
                    : Column(
                        children: [
                          _requestsCard(),
                          const SizedBox(height: 20),
                          _staffCard(),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------ PENDING REQUESTS CARD -----------------------
  Widget _requestsCard() {
    return _modernCard(
      title: "Pending Login Requests",
      icon: Icons.how_to_reg,
      trailing: IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: _loadRequests,
      ),
      child: loadingRequests
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          : requests.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No pending requests"),
                )
              : Column(
                  children: requests.map((r) {
                    final reqId = int.tryParse("${r["RequestId"]}") ?? 0;
                    final staffId = int.tryParse("${r["ContID"]}") ?? 0;
                    final name = (r["EmpUName"] ?? "User").toString();

                    return _tileCard(
                      icon: Icons.person,
                      title: name,
                      subtitle:
                          "Staff ID: $staffId\nRequested: ${_format(r["RequestedAt"])}",
                      trailing: ElevatedButton.icon(
                        onPressed: () => _approve(reqId, staffId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text("Approve",
                            style: TextStyle(color: Colors.white)),
                      ),
                    );
                  }).toList(),
                ),
    );
  }

  // ----------------------------- STAFF LIST CARD -----------------------------
  Widget _staffCard() {
    return _modernCard(
      title: "All Staff Users",
      icon: Icons.group,
      child: loadingStaffs
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          : staffs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No staff records found"),
                )
              : Column(
                  children: staffs.map((s) {
                    final staffId = int.tryParse("${s["StaffId"]}") ?? 0;
                    final name = (s["EmpUName"] ?? "User").toString();

                    return _tileCard(
                      icon: Icons.person_outline,
                      title: name,
                      subtitle:
                          "ID: $staffId\nLast IN: ${_format(s["LastCheckIn"])}\nLast OUT: ${_format(s["LastCheckOut"])}",
                      trailing: IconButton(
                        icon: const Icon(Icons.history, color: Colors.indigo),
                        onPressed: () => _openAttendancePage(staffId, name),
                      ),
                    );
                  }).toList(),
                ),
    );
  }

  // ----------------------------- CARD WRAPPER -----------------------------
  Widget _modernCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: Icon(icon, color: Colors.indigo),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (trailing != null) trailing
              ],
            ),
            const SizedBox(height: 15),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  // ----------------------------- TILE CARD -----------------------------
  Widget _tileCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade100,
          child: Icon(icon, color: Colors.indigo),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }
}
