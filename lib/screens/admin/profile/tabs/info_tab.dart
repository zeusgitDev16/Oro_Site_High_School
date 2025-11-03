import 'package:flutter/material.dart';

class InfoTab extends StatelessWidget {
  const InfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Info',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildPersonalInformationCard(),
          const SizedBox(height: 16),
          _buildContactInformationCard(),
          const SizedBox(height: 16),
          _buildProfessionalInformationCard(),
        ],
      ),
    );
  }

  Widget _buildPersonalInformationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Full Name', 'Steven Johnson'),
            _buildInfoRow('Employee ID', 'EMP-2023-001'),
            _buildInfoRow('Date of Birth', 'January 15, 1985'),
            _buildInfoRow('Gender', 'Male'),
            _buildInfoRow('Nationality', 'Filipino'),
            _buildInfoRow('Civil Status', 'Married'),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInformationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_mail, color: Colors.green.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Contact Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Email', 'steven.johnson@orosite.edu.ph'),
            _buildInfoRow('Phone', '+63 912 345 6789'),
            _buildInfoRow('Address', 'Oro Site, Cagayan de Oro City, Misamis Oriental'),
            _buildInfoRow('Emergency Contact', 'Maria Johnson - +63 912 345 6790'),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalInformationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Professional Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Position', 'System Administrator'),
            _buildInfoRow('Department', 'Information Technology'),
            _buildInfoRow('Date Hired', 'January 10, 2023'),
            _buildInfoRow('Employment Type', 'Full-time'),
            _buildInfoRow('Work Schedule', 'Monday - Friday, 8:00 AM - 5:00 PM'),
            _buildInfoRow('Supervisor', 'Dr. Maria Santos (Principal)'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
