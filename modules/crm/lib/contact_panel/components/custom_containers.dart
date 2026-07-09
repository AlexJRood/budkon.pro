import 'package:flutter/material.dart';

class Prioritycontainer extends StatelessWidget {
  final bool isPC;
  final String priority;
  const Prioritycontainer({
    super.key,
    required this.priority,
    required this.isPC,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color:
            priority == 'high'
                ? const Color(0xff372b2a)
                : priority == 'medium'
                ? const Color(0xff2e343b)
                : const Color(0xff2f342f),
      ),
      child: Center(
        child: Text(
          overflow: TextOverflow.ellipsis,
          priority,
          style: TextStyle(
            fontSize: isPC ? 12 : 14,
            color:
                priority == 'high'
                    ? const Color(0xffad6a55)
                    : priority == 'medium'
                    ? const Color(0xffa1ece6)
                    : const Color(0xffa6e3b8),
          ),
        ),
      ),
    );
  }
}

class DateContainer extends StatelessWidget {
  final String date;
  final bool isPc;
  const DateContainer({super.key, required this.date, required this.isPc});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: const Color(0xff3e3e3e),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.date_range_outlined,
            size: 19,
            color: Color(0xffc8c8c8),
          ),
          Expanded(
            child: Text(
              overflow: TextOverflow.ellipsis,
              date,
              style: TextStyle(
                fontSize: isPc ? 12 : 12,
                color: const Color(0xffc8c8c8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
