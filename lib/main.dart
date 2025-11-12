import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_config.dart';
import 'firestone_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseConfig);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contactos',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const ContactPage(),
    );
  }
}

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  bool _favorite = false;
  final FireContactService _service = FireContactService();

  Color getColor(Set<WidgetState> states) {
    const Set<WidgetState> interactiveStates = <WidgetState>{
      WidgetState.pressed,
      WidgetState.hovered,
      WidgetState.focused,
    };
    if (states.any(interactiveStates.contains) && _favorite == true) {
      return const Color.fromARGB(255, 171, 243, 149);
    }
    return const Color.fromARGB(255, 243, 130, 122);
  }

  Future<void> _addNote() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();

    if (name.isEmpty && phone.isEmpty && email.isEmpty) return;
    await _service.addNote(name, phone, email, _favorite);
    _name.clear();
    _phone.clear();
    _email.clear();
    _favorite = false;
  }

  Future<void> _editNote(
    String id,
    String oldName,
    String oldPhone,
    String oldEmail,
  ) async {
    final nm = TextEditingController(text: oldName);
    final pn = TextEditingController(text: oldPhone);
    final em = TextEditingController(text: oldEmail);

    final newContent = await showDialog<String>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar Contacto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nm),
                  const SizedBox(height: 15),

                  TextField(controller: pn, keyboardType: TextInputType.phone),
                  const SizedBox(height: 15),

                  TextField(
                    controller: em,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),

                  Checkbox(
                    checkColor: Colors.white,
                    fillColor: WidgetStateProperty.resolveWith(getColor),

                    value: _favorite,
                    onChanged: (bool? value) {
                      setState(() {
                        _favorite = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final datos = [
                      nm.text.trim(),
                      pn.text.trim(),
                      em.text.trim(),
                      _favorite,
                    ];
                    Navigator.pop(context, datos);
                  },

                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (newContent == null || newContent.isEmpty) return;
    await _service.updateNote(id, nm.text, pn.text, em.text, _favorite);
  }

  Future<void> _deleteNote(String id) async {
    await _service.deleteNote(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contactos de Examen')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(
                          hintText: 'Nombre...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addNote(),
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Numero Telefonico...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addNote(),
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Email...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addNote(),
                      ),
                      const SizedBox(height: 10),

                      Checkbox(
                        checkColor: Colors.white,
                        fillColor: WidgetStateProperty.resolveWith(getColor),

                        value: _favorite,
                        onChanged: (bool? value) {
                          setState(() {
                            _favorite = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addNote,
                  child: const Text('Agregar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.getNoteStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final contacts = snapshot.data!.docs;

                if (contacts.isEmpty) {
                  return const Center(child: Text('Sin contactos aún'));
                }

                return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, i) {
                    final doc = contacts[i];
                    final name = doc['name'];
                    final phone = doc['phone'];
                    final email = doc['email'];
                    final favorite = doc['favorite'] ?? false;
                    final Timestamp time = doc['createAt'];
                    final DateTime date = time.toDate();

                    return ListTile(
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: favorite,
                            onChanged: (bool? value) async {
                              await doc.reference.update({'favorite': value});
                            },
                          ),

                          IconButton(
                            icon: const Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Detalles de $name'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Teléfono: $phone'),
                                        Text('Email: $email'),
                                        Text(
                                          'Fecha: ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cerrar'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                           IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteNote(doc.id),
                    )
                        ],
                      ),
                     onTap: () => _editNote(doc.id, name, phone,email)
                    );
                      
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
