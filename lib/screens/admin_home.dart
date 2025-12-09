import 'dart:math';
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

  // 🔍 Staff search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 🔢 Latest app version + filter
  String? _latestVersion;
  bool _loadingLatestVersion = false;

  /// 'all', 'outdated', 'uptodate', 'no_version'
  String _versionFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    await Future.wait([
      _loadRequests(),
      _loadStaffs(),
      _loadLatestVersion(),
    ]);
  }

  Future<void> _loadLatestVersion() async {
    setState(() => _loadingLatestVersion = true);
    try {
      _latestVersion = await AdminApi.getLatestAppVersion();
    } catch (e) {
      debugPrint("Latest version load error: $e");
    }
    setState(() => _loadingLatestVersion = false);
  }

  Future<void> _openAddReleaseDialog() async {
    final controller = TextEditingController();
    String? latestVersion;

    // Fetch current latest version
    try {
      latestVersion = await AdminApi.getLatestAppVersion();
    } catch (e) {
      debugPrint("Error loading latest app version: $e");
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add New App Release"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (latestVersion != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "Current latest: $latestVersion",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "No latest version set yet.",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "New version (e.g. 1.0.2)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final version = controller.text.trim();
      if (version.isEmpty) return;

      try {
        await AdminApi.createAppVersion(version);
        await _loadLatestVersion(); // refresh cached latest version
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("New version $version saved as latest")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
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
      _fetchAll();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
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

  // Semantic version comparison: returns -1, 0, 1
  int _compareVersions(String a, String b) {
    final pa =
        a.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final pb =
        b.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final len = max(pa.length, pb.length);

    for (int i = 0; i < len; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va < vb) return -1;
      if (va > vb) return 1;
    }
    return 0;
  }

  bool _isOutdated(String? appVersion) {
    if (_latestVersion == null) return false;
    if (appVersion == null ||
        appVersion.trim().isEmpty ||
        appVersion.trim() == '-') {
      return false; // handled by "no_version"
    }
    return _compareVersions(appVersion, _latestVersion!) < 0;
  }

  bool _isUpToDateOrNewer(String? appVersion) {
    if (_latestVersion == null) return false;
    if (appVersion == null ||
        appVersion.trim().isEmpty ||
        appVersion.trim() == '-') {
      return false;
    }
    return _compareVersions(appVersion, _latestVersion!) >= 0;
  }

  bool _isNoVersion(String? appVersion) {
    if (appVersion == null) return true;
    final v = appVersion.trim();
    return v.isEmpty || v == '-';
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
  void _openAttendancePage(int staffId, String name, String version) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffAttendancePage(
          preSelectedStaffId: staffId,
          preSelectedName: name,
          preSelectedVersion: version,
        ),
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
        tooltip: "Refresh requests",
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
                    final name =
                        (r["StaffName"] ?? r["EmpUName"] ?? "User").toString();

                    return _tileCard(
                      icon: Icons.person,
                      title: name,
                      subtitle:
                          "User: ${r["EmpUName"]}\nRequested: ${_format(r["RequestedAt"])}",
                      trailing: ElevatedButton.icon(
                        onPressed: () => _approve(reqId, staffId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text("Approve"),
                      ),
                    );
                  }).toList(),
                ),
    );
  }

  // ----------------------------- STAFF LIST CARD -----------------------------
  Widget _staffCard() {
    // Base filter: by name
    List<dynamic> filteredStaffs = staffs.where((s) {
      final staffName =
          (s["StaffName"] ?? s["Username"] ?? "User").toString();
      if (_searchQuery.isEmpty) return true;
      return staffName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Apply version filter
    filteredStaffs = filteredStaffs.where((s) {
      final appVersion = (s["AppVersion"] ?? "").toString();

      switch (_versionFilter) {
        case 'outdated':
          return _isOutdated(appVersion);
        case 'uptodate':
          return _isUpToDateOrNewer(appVersion);
        case 'no_version':
          return _isNoVersion(appVersion);
        case 'all':
        default:
          return true;
      }
    }).toList();

    return _modernCard(
      title: "All Staff Users",
      icon: Icons.group,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh staff list",
            onPressed: () async {
              await _loadStaffs();
              await _loadLatestVersion();
            },
          ),
          IconButton(
            icon: const Icon(Icons.system_update_alt),
            tooltip: "Add new app release",
            onPressed: _openAddReleaseDialog,
          ),
        ],
      ),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🔍 Search box
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search staff by name...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Latest version + filter chips
                    if (_loadingLatestVersion)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: LinearProgressIndicator(minHeight: 2),
                      )
                    else if (_latestVersion != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "Latest app version: $_latestVersion",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ChoiceChip(
                          label: const Text("All"),
                          selected: _versionFilter == 'all',
                          selectedColor: Colors.indigo,
                          labelStyle: TextStyle(
                            color: _versionFilter == 'all'
                                ? Colors.white
                                : Colors.black87,
                          ),
                          onSelected: (_) {
                            setState(() => _versionFilter = 'all');
                          },
                        ),
                        ChoiceChip(
                          label: const Text("Outdated only"),
                          selected: _versionFilter == 'outdated',
                          selectedColor: Colors.indigo,
                          labelStyle: TextStyle(
                            color: _versionFilter == 'outdated'
                                ? Colors.white
                                : Colors.black87,
                          ),
                          onSelected: (_) {
                            setState(() => _versionFilter = 'outdated');
                          },
                        ),
                        ChoiceChip(
                          label: const Text("Up-to-date"),
                          selected: _versionFilter == 'uptodate',
                          selectedColor: Colors.indigo,
                          labelStyle: TextStyle(
                            color: _versionFilter == 'uptodate'
                                ? Colors.white
                                : Colors.black87,
                          ),
                          onSelected: (_) {
                            setState(() => _versionFilter = 'uptodate');
                          },
                        ),
                        ChoiceChip(
                          label: const Text("No version"),
                          selected: _versionFilter == 'no_version',
                          selectedColor: Colors.indigo,
                          labelStyle: TextStyle(
                            color: _versionFilter == 'no_version'
                                ? Colors.white
                                : Colors.black87,
                          ),
                          onSelected: (_) {
                            setState(() => _versionFilter = 'no_version');
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (filteredStaffs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "No staff matched your current filters.",
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      ...filteredStaffs.map((s) {
                        final staffId =
                            int.tryParse("${s["StaffId"]}") ?? 0;
                        final staffName =
                            (s["StaffName"] ?? s["Username"] ?? "User")
                                .toString();
                        final appVersion =
                            (s["AppVersion"] ?? "-").toString();

                        // 🔹 Employee ID (e.g. MZCET0511)
                        final empId =
                            (s["Username"] ?? s["EmpUName"] ?? "-")
                                .toString();

                        return _tileCard(
                          icon: Icons.person_outline,
                          title: staffName,
                          subtitle:
                              "Emp ID: $empId\nApp Version: $appVersion\nLast IN: ${_format(s["LastCheckIn"])}\nLast OUT: ${_format(s["LastCheckOut"])}",
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.history,
                              color: Colors.indigo,
                            ),
                            onPressed: () => _openAttendancePage(
                              staffId,
                              staffName,
                              appVersion,
                            ),
                          ),
                        );
                      }).toList(),
                  ],
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing,
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
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }
}
