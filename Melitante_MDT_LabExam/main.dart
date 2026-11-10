import 'dart:io';

const String reset = '\x1B[0m';
const String purple = '\x1B[35m';
const String lavender = '\x1B[95m';
const String white = '\x1B[97m';
const String muted = '\x1B[90m';

void printHeader(String title) {
  stdout.writeln('\n$purple══════════════════════════════════════════════════════════$reset');
  stdout.writeln('$lavender  $title$reset');
  stdout.writeln('$purple══════════════════════════════════════════════════════════$reset');
}

void showMessage(String message, {bool error = false}) {
  stdout.writeln('${error ? '\x1B[31m' : lavender}$message$reset');
}

String readRequired(String prompt) {
  while (true) {
    stdout.write(prompt);
    final value = stdin.readLineSync();
    if (value == null) {
      throw const FormatException('Input stream closed.');
    }
    if (value.trim().isNotEmpty) return value.trim();
    showMessage('Input cannot be empty. Please try again.', error: true);
  }
}

int readPositiveInt(String prompt) {
  while (true) {
    final value = readRequired(prompt);
    try {
      final number = int.parse(value);
      if (number > 0) return number;
      showMessage('Enter a whole number greater than zero.', error: true);
    } on FormatException {
      showMessage('Invalid number. Enter a whole number (example: 5).', error: true);
    } catch (error) {
      showMessage('Unable to read that value: $error', error: true);
    }
  }
}

/// Reusable behavior shared by records that need creation timestamps.
mixin Timestamped {
  DateTime createdAt = DateTime.now();

  String get createdLabel => createdAt.toLocal().toString().split('.').first;
}

/// Parent type for the two kinds of records managed by the center.
abstract class CenterRecord with Timestamped {
  final String _id;
  String _name;

  CenterRecord({required String id, required String name})
      : _id = id.trim(),
        _name = name.trim();

  String get id => _id;
  String get name => _name;

  set name(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('Name cannot be empty.');
    }
    _name = value.trim();
  }

  String get recordType;
  String displayDetails();
}

/// A resource has a quantity that changes when copies are borrowed or returned.
class LearningResource extends CenterRecord {
  final String category;
  final double replacementCost;
  int _totalCopies;
  int _availableCopies;

  LearningResource({
    required super.id,
    required super.name,
    required this.category,
    required int totalCopies,
    required this.replacementCost,
  })  : _totalCopies = totalCopies,
        _availableCopies = totalCopies {
    if (totalCopies <= 0) throw ArgumentError('Copies must be greater than zero.');
    if (replacementCost < 0) throw ArgumentError('Cost cannot be negative.');
  }

  @override
  String get recordType => 'Learning Resource';

  int get totalCopies => _totalCopies;
  int get availableCopies => _availableCopies;
  int get borrowedCopies => _totalCopies - _availableCopies;
  bool get isAvailable => _availableCopies > 0;

  bool borrowCopy() {
    if (!isAvailable) return false;
    _availableCopies--;
    return true;
  }

  bool returnCopy() {
    if (_availableCopies >= _totalCopies) return false;
    _availableCopies++;
    return true;
  }

  @override
  String displayDetails() =>
      '[$id] $name | Category: $category | Available: $_availableCopies/$_totalCopies | '
      'Borrowed: $borrowedCopies | Replacement cost: PHP ${replacementCost.toStringAsFixed(2)}';
}

/// A registered participant can have multiple active borrow transactions.
class Participant extends CenterRecord {
  final String sectionOrGroup;
  final Map<String, bool> _borrowedTransactions = {};

  Participant({
    required super.id,
    required super.name,
    required this.sectionOrGroup,
  });

  @override
  String get recordType => 'Participant';

  int get activeBorrowCount => _borrowedTransactions.values.where((active) => active).length;

  void addBorrow(String transactionId) {
    _borrowedTransactions[transactionId] = true;
  }

  void closeBorrow(String transactionId) {
    if (_borrowedTransactions.containsKey(transactionId)) {
      _borrowedTransactions[transactionId] = false;
    }
  }

  @override
  String displayDetails() =>
      '[$id] $name | Section/Group: $sectionOrGroup | Active borrows: $activeBorrowCount';
}

class BorrowTransaction with Timestamped {
  final String transactionId;
  final String resourceId;
  final String participantId;
  final DateTime borrowedAt;
  DateTime? returnedAt;
  bool _isActive;

  BorrowTransaction({
    required this.transactionId,
    required this.resourceId,
    required this.participantId,
  })  : borrowedAt = DateTime.now(),
        _isActive = true;

  bool get isActive => _isActive;

  void markReturned() {
    if (!_isActive) throw StateError('This transaction has already been returned.');
    _isActive = false;
    returnedAt = DateTime.now();
  }

  String displayDetails() =>
      '$transactionId | Resource: $resourceId | Participant: $participantId | '
      'Borrowed: ${borrowedAt.toLocal().toString().split('.').first} | '
      'Status: ${_isActive ? 'BORROWED' : 'RETURNED'}'
      '${returnedAt == null ? '' : ' | Returned: ${returnedAt!.toLocal().toString().split('.').first}'}';
}

class CommunityLearningCenter {
  final List<LearningResource> resources = [];
  final List<Participant> participants = [];
  final List<BorrowTransaction> transactions = [];

  // Maps provide direct lookup by each record's identification number.
  final Map<String, LearningResource> resourceById = {};
  final Map<String, Participant> participantById = {};
  final Map<String, BorrowTransaction> transactionById = {};

  int _nextTransactionNumber = 1;

  bool addResource(LearningResource resource) {
    if (resourceById.containsKey(resource.id)) return false;
    resources.add(resource);
    resourceById[resource.id] = resource;
    return true;
  }

  bool addParticipant(Participant participant) {
    if (participantById.containsKey(participant.id)) return false;
    participantById[participant.id] = participant;
    participants.add(participant);
    return true;
  }

  BorrowTransaction? borrowResource(String resourceId, String participantId) {
    final resource = resourceById[resourceId];
    final participant = participantById[participantId];
    if (resource == null || participant == null || !resource.isAvailable) return null;

    // Only create a transaction after all checks pass and the copy is reserved.
    if (!resource.borrowCopy()) return null;
    final transaction = BorrowTransaction(
      transactionId: 'TX${_nextTransactionNumber.toString().padLeft(4, '0')}',
      resourceId: resourceId,
      participantId: participantId,
    );
    _nextTransactionNumber++;
    transactions.add(transaction);
    transactionById[transaction.transactionId] = transaction;
    participant.addBorrow(transaction.transactionId);
    return transaction;
  }

  bool returnResource(String transactionId) {
    final transaction = transactionById[transactionId];
    if (transaction == null || !transaction.isActive) return false;
    final resource = resourceById[transaction.resourceId];
    final participant = participantById[transaction.participantId];
    if (resource == null || participant == null) return false;

    try {
      if (!resource.returnCopy()) return false;
      transaction.markReturned();
      participant.closeBorrow(transactionId);
      return true;
    } on StateError {
      return false;
    }
  }

  /// Polymorphic display: both subclasses are treated as CenterRecord objects.
  void displayAllRecords() {
    final List<CenterRecord> allRecords = [...resources, ...participants];
    if (allRecords.isEmpty) {
      showMessage('No records have been registered yet.');
      return;
    }
    for (final record in allRecords) {
      stdout.writeln('${record.recordType}: ${record.displayDetails()}');
    }
  }

  CenterRecord? findRecord(String id) => resourceById[id] ?? participantById[id];
}

void addLearningResource(CommunityLearningCenter center) {
  printHeader('ADD LEARNING RESOURCE');
  final id = readRequired('Resource ID: ');
  if (center.resourceById.containsKey(id)) {
    showMessage('A resource with ID $id already exists.', error: true);
    return;
  }
  final name = readRequired('Resource name/title: ');
  final category = readRequired('Category (Book, Device, Module, etc.): ');
  final copies = readPositiveInt('Number of copies: ');
  final costText = readRequired('Replacement cost per copy (PHP): ');
  final double cost;
  try {
    cost = double.parse(costText);
    if (cost < 0) throw const FormatException();
  } on FormatException {
    showMessage('Invalid cost. Use a non-negative number (example: 250.50).', error: true);
    return;
  }
  final resource = LearningResource(
    id: id,
    name: name,
    category: category,
    totalCopies: copies,
    replacementCost: cost,
  );
  final added = center.addResource(resource);
  showMessage(added ? 'Resource registered successfully.' : 'Unable to register duplicate resource ID.', error: !added);
}

void registerParticipant(CommunityLearningCenter center) {
  printHeader('REGISTER PARTICIPANT');
  final id = readRequired('Participant ID: ');
  if (center.participantById.containsKey(id)) {
    showMessage('A participant with ID $id already exists.', error: true);
    return;
  }
  final name = readRequired('Participant full name: ');
  final group = readRequired('Section/Group: ');
  final participant = Participant(id: id, name: name, sectionOrGroup: group);
  final added = center.addParticipant(participant);
  showMessage(added ? 'Participant registered successfully.' : 'Duplicate participant ID.', error: !added);
}

void viewResources(CommunityLearningCenter center) {
  printHeader('LEARNING RESOURCES');
  if (center.resources.isEmpty) {
    showMessage('No learning resources found.');
    return;
  }
  for (final resource in center.resources) {
    stdout.writeln(resource.displayDetails());
  }
}

void viewParticipants(CommunityLearningCenter center) {
  printHeader('REGISTERED PARTICIPANTS');
  if (center.participants.isEmpty) {
    showMessage('No participants found.');
    return;
  }
  for (final participant in center.participants) {
    stdout.writeln(participant.displayDetails());
  }
}

void borrowResource(CommunityLearningCenter center) {
  printHeader('BORROW LEARNING RESOURCE');
  final resourceId = readRequired('Resource ID: ');
  final participantId = readRequired('Participant ID: ');
  if (!center.resourceById.containsKey(resourceId)) {
    showMessage('Resource ID not found. Register or check the ID first.', error: true);
    return;
  }
  if (!center.participantById.containsKey(participantId)) {
    showMessage('Participant ID not found. Register or check the ID first.', error: true);
    return;
  }
  final transaction = center.borrowResource(resourceId, participantId);
  if (transaction == null) {
    showMessage('Borrowing could not be completed. No copies may be available.', error: true);
  } else {
    showMessage('Borrowing successful. Transaction ID: ${transaction.transactionId}');
  }
}

void returnResource(CommunityLearningCenter center) {
  printHeader('RETURN BORROWED RESOURCE');
  final transactionId = readRequired('Transaction ID: ');
  final transaction = center.transactionById[transactionId];
  if (transaction == null) {
    showMessage('Transaction ID not found.', error: true);
    return;
  }
  if (!transaction.isActive) {
    showMessage('This transaction was already returned. Duplicate return prevented.', error: true);
    return;
  }
  final returned = center.returnResource(transactionId);
  showMessage(returned
      ? 'Resource returned successfully. Available quantity has been updated.'
      : 'Return could not be completed.', error: !returned);
}

void viewTransactions(CommunityLearningCenter center) {
  printHeader('TRANSACTION HISTORY');
  if (center.transactions.isEmpty) {
    showMessage('No transactions found.');
    return;
  }
  for (final transaction in center.transactions) {
    stdout.writeln(transaction.displayDetails());
  }
}

void searchRecords(CommunityLearningCenter center) {
  printHeader('SEARCH RECORDS');
  final id = readRequired('Enter a resource or participant ID: ');
  final record = center.findRecord(id);
  if (record == null) {
    showMessage('No resource or participant found with ID $id.', error: true);
  } else {
    stdout.writeln('${record.recordType}: ${record.displayDetails()}');
  }
}

void showMenu() {
  stdout.writeln('$white\n1. Add Learning Resource');
  stdout.writeln('2. Register Participant');
  stdout.writeln('3. View Learning Resources');
  stdout.writeln('4. View Participants');
  stdout.writeln('5. Borrow Resource');
  stdout.writeln('6. Return Resource');
  stdout.writeln('7. View Transactions');
  stdout.writeln('8. Search Records');
  stdout.writeln('9. View All Records');
  stdout.writeln('0. Exit$reset');
}

void main() {
  final center = CommunityLearningCenter();
  bool isRunning = true;
  stdout.writeln('$purple');
  printHeader('COMMUNITY LEARNING CENTER MANAGEMENT SYSTEM');
  stdout.writeln('$muted  Organizing resources, participants, and learning transactions.$reset');

  while (isRunning) {
    showMenu();
    stdout.write('\nSelect an option: ');
    final choice = stdin.readLineSync()?.trim() ?? '';

    try {
      switch (choice) {
        case '1':
          addLearningResource(center);
          break;
        case '2':
          registerParticipant(center);
          break;
        case '3':
          viewResources(center);
          break;
        case '4':
          viewParticipants(center);
          break;
        case '5':
          borrowResource(center);
          break;
        case '6':
          returnResource(center);
          break;
        case '7':
          viewTransactions(center);
          break;
        case '8':
          searchRecords(center);
          break;
        case '9':
          printHeader('ALL CENTER RECORDS');
          center.displayAllRecords();
          break;
        case '0':
          isRunning = false;
          showMessage('Thank you for using the Community Learning Center Management System.');
          break;
        default:
          showMessage('Invalid menu choice. Please select 0–9.', error: true);
      }
    } on FormatException catch (error) {
      showMessage('Input error: ${error.message}', error: true);
    } on ArgumentError catch (error) {
      showMessage('Invalid data: ${error.message}', error: true);
    } catch (error) {
      showMessage('An unexpected error occurred: $error', error: true);
    }
  }
}
