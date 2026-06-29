import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_notifier.dart';

class NotificationDetailPage extends StatelessWidget {
  const NotificationDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    

    return Scaffold(

      /// APP BAR WITH BACK BUTTON
      appBar: AppBar(
        elevation: 0,
        
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Notification Detail",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      /// PAGE BODY
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          /// ALERT BADGE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning, size: 16, color: Colors.red),
                SizedBox(width: 5),
                Text(
                  "URGENT ALERT",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// TITLE
          const Text(
            "Health Alert: Egg Production Drop",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          /// DATE
          const Row(
            children: [
              Icon(Icons.calendar_today, size: 16),
              SizedBox(width: 5),
              Text("Oct 24, 2023"),
              SizedBox(width: 10),
              Text("•"),
              SizedBox(width: 10),
              Icon(Icons.schedule, size: 16),
              SizedBox(width: 5),
              Text("09:45 AM"),
            ],
          ),

          const SizedBox(height: 25),

          /// MESSAGE CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "We noticed a 2% drop in egg production in House 4.",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  "Please check the water supply and environmental controls immediately.",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  "Immediate attention is recommended to ensure flock welfare.",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          /// MARK READ BUTTON
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.done_all),
              label: const Text("Mark as read"),
            ),
          )
        ],
      ),
    );
  }
}
