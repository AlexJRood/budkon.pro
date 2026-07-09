part of 'issue_details_dialog.dart';

const List<Map<String, String>> _featureOptions = [
  {'value': 'wall', 'label': 'Wall'},
  {'value': 'feedback', 'label': 'Feedback'},
  {'value': 'portal', 'label': 'Portal'},
  {'value': 'crm', 'label': 'CRM'},
  {'value': 'chat', 'label': 'Chat'},
  {'value': 'ai', 'label': 'AI'},
  {'value': 'nm', 'label': 'Network Monitoring'},
  {'value': 'docs', 'label': 'Docs'},
  {'value': 'tms', 'label': 'TMS'},
  {'value': 'calendar', 'label': 'Calendar'},
  {'value': 'cloud', 'label': 'Cloud'},
  {'value': 'mail', 'label': 'Mail'},
  {'value': 'client_panel', 'label': 'Client Panel'},
  {'value': 'finance', 'label': 'Finance'},
  {'value': 'notifications', 'label': 'Notifications'},
  {'value': 'profile', 'label': 'Profile'},
  {'value': 'assosiation', 'label': 'Association'},
  {'value': 'fav', 'label': 'Favourites'},
  {'value': 'browse_list', 'label': 'Browse List'},
];

const List<Map<String, String>> _teamOptions = [
  {'value': 'team alex', 'label': 'Team Alex'},
  {'value': 'team younis', 'label': 'Team Younis'},
  {'value': 'team ansaf', 'label': 'Team Ansaf'},
];

const List<Map<String, String>> _appOptions = [
  {'value': 'hously', 'label': 'Hously'},
  {'value': 'panel', 'label': 'Panel'},
  {'value': 'extractly', 'label': 'Extractly'},
];

const List<Map<String, String>> _priorityOptions = [
  {'value': 'lod', 'label': 'Live or Dead'},
  {'value': 'critical', 'label': 'Critical'},
  {'value': 'high', 'label': 'High'},
  {'value': 'mid', 'label': 'Medium'},
  {'value': 'low', 'label': 'Low'},
];

class _MemberLite {
  final int id;
  final String name;
  final String? avatar;

  const _MemberLite(this.id, this.name, this.avatar);
}