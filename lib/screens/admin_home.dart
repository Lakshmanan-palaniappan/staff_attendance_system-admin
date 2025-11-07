import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/admin_api.dart';

const backendBaseUrl = "https://staffattendance.loca.lt";

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
  IO.Socket? socket;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _connectSocket();
  }

  Future<void> _fetchData() async {
    await Future.wait([_loadRequests(), _loadStaffs()]);
  }

  Future<void> _loadRequests() async {
    setState(() => loadingRequests = true);
    try {
      requests = await AdminApi.getPendingRequests();
    } catch (e) {
      debugPrint("Error fetching requests: $e");
    } finally {
      setState(() => loadingRequests = false);
    }
  }

  Future<void> _loadStaffs() async {
    setState(() => loadingStaffs = true);
    try {
      staffs = await AdminApi.getAllStaffs();
    } catch (e) {
      debugPrint("Error fetching staffs: $e");
    } finally {
      setState(() => loadingStaffs = false);
    }
  }

  void _connectSocket() {
    socket = IO.io(backendBaseUrl, IO.OptionBuilder().setTransports(['websocket']).build());
    socket!.onConnect((_) => debugPrint("Admin socket connected"));
    socket!.on('new_login_request', (data) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🔔 New login request: ${data['staff']['Name']}")),
      );
      _loadRequests();
    });
  }

  Future<void> _approveRequest(int requestId, int staffId) async {
    try {
      await AdminApi.approveRequest(requestId, staffId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Request approved")),
      );
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.indigo,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isWide
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildRequestsCard()),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: _buildStaffsCard()),
            ],
          )
              : ListView(
            children: [
              _buildRequestsCard(),
              const SizedBox(height: 16),
              _buildStaffsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pending Login Requests",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (loadingRequests)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            if (!loadingRequests && requests.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No pending requests"))),
            if (!loadingRequests && requests.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (_, i) {
                    final r = requests[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(r["Name"] ?? "Unknown"),
                        subtitle: Text("Username: ${r["Username"]}\nID: ${r["IdCardNumber"]}"),
                        trailing: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () => _approveRequest(r["RequestId"], r["StaffId"]),
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text("Approve", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("All Staff Members",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            if (loadingStaffs)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            if (!loadingStaffs && staffs.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No staff records found"))),
            if (!loadingStaffs && staffs.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: staffs.length,
                  itemBuilder: (_, i) {
                    final s = staffs[i];
                    return Card(
                      color: Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(
                            (s["Name"]?.substring(0, 1) ?? "?").toUpperCase(),
                            style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(s["Name"] ?? "Unknown"),
                        subtitle: Text(
                          "Username: ${s["Username"]}\nID Card: ${s["IdCardNumber"]}",
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
