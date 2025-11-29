import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mission_model.dart';

class MissionCard extends StatelessWidget {
  const MissionCard({super.key, required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final missions = context.read<MissionsModel>();
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: mission.completed,
          onChanged: (_) => missions.toggleMission(mission.id),
        ),
        title: Text(mission.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(mission.description),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('+${mission.xpReward} XP'),
        ),
      ),
    );
  }
}


