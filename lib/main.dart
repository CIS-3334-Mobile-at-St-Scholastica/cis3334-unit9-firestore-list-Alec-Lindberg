import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore List',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2962FF)),
      home: const ItemListApp(),
    );
  }
}

class ItemListApp extends StatefulWidget {
  const ItemListApp({super.key});

  @override
  State<ItemListApp> createState() => _ItemListAppState();
}

class _ItemListAppState extends State<ItemListApp> {
  // text controller
  final TextEditingController _newItemTextField = TextEditingController();

  // firestore collection
  late final CollectionReference<Map<String, dynamic>> items;

  @override
  void initState() {
    super.initState();
    items = FirebaseFirestore.instance.collection('ITEMS');
  }

  // ========== ACTIONS ==========

  Future<void> _addItem() async {
    final newItem = _newItemTextField.text.trim();
    if (newItem.isEmpty) return;

    await items.add({
      'item_name': newItem,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _newItemTextField.clear();
  }

  Future<void> _removeItemAt(String id) async {
    await items.doc(id).delete();
  }

  // ========== WIDGET HELPERS ==========

  /// Row with textfield + button
  Widget itemInputWidget() {
    return Row(
      children: [
        Expanded(child: nameTextFieldWidget()),
        const SizedBox(width: 12),
        addButtonWidget(),
      ],
    );
  }

  /// Just the TextField
  Widget nameTextFieldWidget() {
    return TextField(
      controller: _newItemTextField,
      onSubmitted: (_) => _addItem(),
      decoration: const InputDecoration(
        labelText: 'New Item Name',
        border: OutlineInputBorder(),
      ),
    );
  }

  /// Just the add button
  Widget addButtonWidget() {
    return FilledButton(
      onPressed: _addItem,
      child: const Text('Add'),
    );
  }

  /// The list area that listens to Firestore
  Widget itemListWidget() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: items.orderBy('createdAt', descending: false).snapshots(),
      builder: (context, snapshot) {
        // loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // no data
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No items yet.'));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            return itemTileWidget(doc);
          },
        );
      },
    );
  }

  /// One tile (wrapped in Dismissible) built from a Firestore document
  Widget itemTileWidget(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final String id = doc.id;
    final String name = (doc.data()['item_name']) ?? '';

    return Dismissible(
      key: ValueKey(id),
      background: Container(color: Colors.red),
      onDismissed: (_) => _removeItemAt(id),
      child: ListTile(
        leading: const Icon(Icons.check_box),
        title: Text(name),
        onTap: () => _removeItemAt(id),
      ),
    );
  }

  // ========== BUILD ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore List Demo')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          children: [
            itemInputWidget(),
            const SizedBox(height: 24),
            Expanded(child: itemListWidget()),
          ],
        ),
      ),
    );
  }
}

