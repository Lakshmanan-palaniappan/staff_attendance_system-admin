import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/admin_api.dart';

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
    _fetch();
  }

  Future<void> _fetch() async {
    await Future.wait([_loadRequests(), _loadStaffs()]);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Approved successfully")),
      );
      _fetch();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // FORMAT time nicely
  String formatTime(dynamic t) {
    if (t == null) return "—";

    final dt = DateTime.parse(t.toString());
    return "${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.indigo,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, "/login");
            },
          )
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _fetch,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),

            child: width < 900
                ? Column(
              children: [
                _requestsCard(),
                const SizedBox(height: 20),
                _staffCard(),
              ],
            )
                : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _requestsCard()),
                const SizedBox(width: 20),
                Expanded(flex: 3, child: _staffCard()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================== REQUEST CARD ===============================
  Widget _requestsCard() {
    return _modernCard(
      title: "Pending Login Requests",
      icon: Icons.pending_actions,
      trailing: IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: _loadRequests,
      ),
      child: loadingRequests
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      )
          : requests.isEmpty
          ? const Padding(
        padding: EdgeInsets.all(20),
        child: Text("No pending requests"),
      )
          : Column(
        children: requests.map((r) {
          return _tileCard(
            icon: Icons.person,
            title: r["Name"],
            subtitle:
            "Username: ${r["Username"]}\nID: ${r["IdCardNumber"]}",
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () =>
                  _approve(r["RequestId"], r["StaffId"]),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text("Approve",
                  style: TextStyle(color: Colors.white)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =========================== STAFF CARD ===============================
  Widget _staffCard() {
    return _modernCard(
      title: "All Staff Members",
      icon: Icons.group_rounded,
      child: loadingStaffs
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      )
          : staffs.isEmpty
          ? const Padding(
        padding: EdgeInsets.all(20),
        child: Text("No staff records found"),
      )
          : Column(
        children: staffs.map((s) {
          return _tileCard(
            icon: Icons.person_outline,
            title: s["Name"],
            subtitle:
            "Username: ${s["Username"]}\n"
                "ID Card: ${s["IdCardNumber"]}\n"
                "Last Check-In: ${formatTime(s["LastCheckIn"])}\n"
                "Last Check-Out: ${formatTime(s["LastCheckOut"])}",
          );
        }).toList(),
      ),
    );
  }

  // ====================== Modern Card Wrapper =======================
  Widget _modernCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: Icon(icon, color: Colors.indigo),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (trailing != null) trailing
              ],
            ),
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  // ====================== Tile Card (each item) =======================
  Widget _tileCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade100,
          child: Icon(icon, color: Colors.indigo),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }
}
