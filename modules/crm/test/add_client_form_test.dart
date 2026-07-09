import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crm/crm/add_field/add_client.dart';
import 'package:crm/data/clients/client_provider.dart';
import 'package:crm/data/clients/contact_type_provider.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/shared/models/user_contact_status_model.dart';
import 'package:crm/shared/models/contact_type_model.dart';
import 'package:crm/shared/models/service_type_model.dart';

// ---------------------------------------------------------------------------
// Fake implementations
// ---------------------------------------------------------------------------

class _FakeContactTypeProvider extends ContactTypeProvider {
  final List<ContactTypeModel> types;
  final List<ServiceTypeModel> serviceTypes;

  _FakeContactTypeProvider({
    this.types = const [],
    this.serviceTypes = const [],
  });

  @override
  List<ContactTypeModel> get contactType => types;

  @override
  List<ServiceTypeModel> get contactServiceType => serviceTypes;

  @override
  Future<void> getContactType(dynamic ref) async {}

  @override
  Future<void> getContactServiceType(dynamic ref) async {}
}

/// A fake [ClientNotifier] that records the last addClient call.
class _FakeClientNotifier extends ClientNotifier {
  _FakeClientNotifier() : super(_FakeRef());

  UserContactModel? lastAdded;
  Object? errorToThrow;

  @override
  Future<List<UserContactStatusModel>> fetchStatuses(dynamic ref) async => [];

  @override
  Future<List<UserContactModel>> fetchClientsList({
    int? status,
    String? sort,
    String? searchQuery,
  }) async =>
      [];

  @override
  Future<void> addClient(UserContactModel client) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastAdded = client;
  }
}

/// Minimal fake Ref — only used to satisfy the constructor.
class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _CountingClientNotifier extends _FakeClientNotifier {
  final void Function() onAdd;
  _CountingClientNotifier(this.onAdd);

  @override
  Future<void> addClient(UserContactModel client) async {
    onAdd();
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildUnderTest({
  _FakeClientNotifier? notifier,
  _FakeContactTypeProvider? ctProvider,
}) {
  final fakeNotifier = notifier ?? _FakeClientNotifier();
  final fakeCtProvider = ctProvider ?? _FakeContactTypeProvider();

  return ProviderScope(
    overrides: [
      clientProvider.overrideWith((_) => fakeNotifier),
      contactTypeProvider.overrideWith((_) => fakeCtProvider),
    ],
    child: const MaterialApp(home: Scaffold(body: AddClientForm())),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AddClientForm — collapsed state', () {
    testWidgets('shows add (+) button when closed', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pump();

      // The + button must be visible
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('tapping + opens the form', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Form fields should now be visible
      expect(find.byType(TextFormField), findsWidgets);
    });
  });

  group('AddClientForm — form validation', () {
    testWidgets('Save with empty name shows validation error', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pump();

      // Open form
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Tap Save without filling name
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a name'), findsOneWidget);
    });

    testWidgets('Save with name filled does not show name error', (tester) async {
      final notifier = _FakeClientNotifier();
      await tester.pumpWidget(_buildUnderTest(notifier: notifier));
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'Jan',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a name'), findsNothing);
    });
  });

  group('AddClientForm — submit flow', () {
    testWidgets('successful save shows success SnackBar', (tester) async {
      final notifier = _FakeClientNotifier();
      await tester.pumpWidget(_buildUnderTest(notifier: notifier));
      await tester.pump();

      // Open
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Fill name
      await tester.enterText(find.byType(TextFormField).first, 'Anna');

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Client added successfully'), findsOneWidget);
    });

    testWidgets('successful save closes the form', (tester) async {
      final notifier = _FakeClientNotifier();
      await tester.pumpWidget(_buildUnderTest(notifier: notifier));
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Piotr');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Form fields should be gone
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('addClient is called with correct name and lastName', (tester) async {
      final notifier = _FakeClientNotifier();
      await tester.pumpWidget(_buildUnderTest(notifier: notifier));
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Maria');
      await tester.enterText(fields.at(1), 'Nowak');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(notifier.lastAdded?.name, 'Maria');
      expect(notifier.lastAdded?.lastName, 'Nowak');
    });

    testWidgets('empty lastName is sent as null', (tester) async {
      final notifier = _FakeClientNotifier();
      await tester.pumpWidget(_buildUnderTest(notifier: notifier));
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Solo');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(notifier.lastAdded?.lastName, isNull);
    });

    testWidgets('API error shows red SnackBar with message', (tester) async {
      final notifier = _FakeClientNotifier()
        ..errorToThrow = Exception('HTTP 500');

      await tester.pumpWidget(_buildUnderTest(notifier: notifier));
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Err');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to add client: Exception: HTTP 500'), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.red);
    });

    testWidgets('form stays open after API error', (tester) async {
      final notifier = _FakeClientNotifier()
        ..errorToThrow = Exception('fail');

      await tester.pumpWidget(_buildUnderTest(notifier: notifier));
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Err');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Form must still be visible
      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('AddClientForm — cancel', () {
    testWidgets('Cancel closes the form without calling addClient', (tester) async {
      final notifier = _FakeClientNotifier();
      await tester.pumpWidget(_buildUnderTest(notifier: notifier));
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Discard');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(notifier.lastAdded, isNull);
      expect(find.text('Save'), findsNothing);
    });
  });

  group('UserContactModel.toCreateJson', () {
    test('sends only name when other fields are empty', () {
      final m = UserContactModel(id: 0, name: 'Jan');
      final json = m.toCreateJson();
      expect(json['name'], 'Jan');
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('last_name'), isFalse);
      expect(json.containsKey('transactions_preview'), isFalse);
      expect(json.containsKey('favorite_boards'), isFalse);
    });

    test('omits empty lastName from payload', () {
      final m = UserContactModel(id: 0, name: 'Jan', lastName: '');
      expect(m.toCreateJson().containsKey('last_name'), isFalse);
    });

    test('includes lastName when non-empty', () {
      final m = UserContactModel(id: 0, name: 'Jan', lastName: 'Kowalski');
      expect(m.toCreateJson()['last_name'], 'Kowalski');
    });

    test('contact_status coerced to int when stored as string', () {
      final m = UserContactModel(id: 0, name: 'X', contactStatus: '3');
      expect(m.toCreateJson()['contact_status'], 3);
    });

    test('service_type coerced to int when stored as string', () {
      final m = UserContactModel(id: 0, name: 'X', serviceType: '7');
      expect(m.toCreateJson()['service_type'], 7);
    });

    test('contact_type sent as int FK', () {
      final m = UserContactModel(id: 0, name: 'X', contactType: 5);
      expect(m.toCreateJson()['contact_type'], 5);
    });
  });

  group('AddClientForm — email validation', () {
    testWidgets('invalid email shows validation error', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Jan');       // name
      await tester.enterText(fields.at(2), 'notanemail'); // email

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email address'), findsOneWidget);
    });

    testWidgets('valid email passes validation', (tester) async {
      final notifier = _FakeClientNotifier();
      await tester.pumpWidget(_buildUnderTest(notifier: notifier));
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Jan');
      await tester.enterText(fields.at(2), 'jan@example.com');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email address'), findsNothing);
      expect(notifier.lastAdded?.email, 'jan@example.com');
    });

    testWidgets('empty email is accepted (field is optional)', (tester) async {
      final notifier = _FakeClientNotifier();
      await tester.pumpWidget(_buildUnderTest(notifier: notifier));
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'NoMail');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email address'), findsNothing);
      expect(notifier.lastAdded?.email, isNull);
    });
  });

  group('AddClientForm — debounce', () {
    testWidgets('rapid double-tap calls addClient only once', (tester) async {
      var callCount = 0;
      final countingNotifier = _CountingClientNotifier(() => callCount++);

      await tester.pumpWidget(_buildUnderTest(notifier: countingNotifier));
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Rapid');

      // Tap Save twice in quick succession
      await tester.tap(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(callCount, 1);
    });
  });

  group('AddClientForm — dropdowns', () {
    testWidgets('contact type options appear in dropdown', (tester) async {
      final ctProvider = _FakeContactTypeProvider(
        types: [
          ContactTypeModel(id: 1, contactType: 'buyer', label: 'Kupujący'),
          ContactTypeModel(id: 2, contactType: 'seller', label: 'Sprzedający'),
        ],
      );

      await tester.pumpWidget(_buildUnderTest(ctProvider: ctProvider));
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Open client type dropdown
      await tester.tap(find.text('Client Type'));
      await tester.pumpAndSettle();

      expect(find.text('Kupujący'), findsWidgets);
      expect(find.text('Sprzedający'), findsWidgets);
    });

    testWidgets('service type options appear in dropdown', (tester) async {
      final ctProvider = _FakeContactTypeProvider(
        serviceTypes: [
          ServiceTypeModel(id: 1, serviceType: 'rent', label: 'Wynajem'),
        ],
      );

      await tester.pumpWidget(_buildUnderTest(ctProvider: ctProvider));
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Service Type'));
      await tester.pumpAndSettle();

      expect(find.text('Wynajem'), findsWidgets);
    });
  });
}
