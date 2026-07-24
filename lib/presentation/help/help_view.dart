import 'package:flutter/material.dart';

class HelpView extends StatelessWidget {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("How to Use"),
        backgroundColor: colorScheme.surface,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildHelpItem(
              context: context,
              title: "Getting Started",
              content:
                  "To begin, go to the 'AI Engine' section in Settings and download the SmolLM model to your device. Then, under 'Notification Interceptor', grant 'Listener Access' and 'Post Notifications' permissions. Finally, use the 'Monitored Apps' search to pick which financial apps to monitor for transactions.",
            ),
            _buildHelpItem(
              context: context,
              title: "Automatic Transaction Detection",
              content:
                  "The app securely listens for notifications from your monitored apps on your device. When a notification matches your selected keywords, the offline AI model automatically extracts the transaction amount, merchant, and category, and saves it in a PENDING state.",
            ),
            _buildHelpItem(
              context: context,
              title: "Approving, Rejecting & Editing",
              content:
                  "When a new transaction is detected, you will receive an interactive notification where you can quickly Approve, Reject, or Edit it. Tapping Edit opens the pre-filled form directly. You can also review, approve, reject, or restore PENDING transactions anytime from the Audit tab.",
            ),
            _buildHelpItem(
              context: context,
              title: "Adding Transactions Manually",
              content:
                  "Tap the '+' button on the Home tab to add a transaction manually. Choose 'AI Assistant' to simply describe your purchase in plain language and have it auto-approved. Alternatively, select 'Manual Entry' to fill out the blank form yourself.",
            ),
            _buildHelpItem(
              context: context,
              title: "Managing Accounts",
              content:
                  "You can add, edit, or delete accounts by navigating to Settings and tapping 'Manage Accounts', or by clicking the 'Manage' link on the Dashboard. On the Dashboard, swipe left and right between your cards to view different accounts. Note that you cannot delete an account if it already has associated transactions.",
            ),
            _buildHelpItem(
              context: context,
              title: "Customizing Your Charts",
              content:
                  "Your Dashboard charts can be customized in Settings under the 'Chart & Insights' section. You can change the chart type to Line, Area, or Bar, and switch the data mode between overall cashflow and comparing two specific categories.",
            ),
            _buildHelpItem(
              context: context,
              title: "Exporting Your Data",
              content:
                  "You can export all your transaction data at any time from Settings by tapping 'Export Data'. The tool allows you to choose between CSV or JSON formats, and you can fully customize and reorder the columns included in the export.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          iconColor: colorScheme.primary,
          collapsedIconColor: colorScheme.onSurfaceVariant,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Text(
                content,
                style: const TextStyle(
                  color: Colors.grey,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
