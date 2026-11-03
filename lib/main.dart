import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Reportes Escolares',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E5C8A)),
        useMaterial3: true,
      ),
      home: const PantallaLogin(),
    );
  }
}

// ---------------------------------------------------------------------------
// SERVICIO PARA GESTIONAR EL ARCHIVO JSON LOCAL
// ---------------------------------------------------------------------------
class JsonAuthService {
  static Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'usuarios.json');
    final file = File(path);

    if (!await file.exists()) {
      await file.writeAsString(jsonEncode([]));
    }
    return file;
  }

  // Función para encriptar/hashear la contraseña con SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // Leer la lista de usuarios del JSON
  static Future<List<dynamic>> obtenerUsuarios() async {
    try {
      final file = await _getFile();
      final contenido = await file.readAsString();
      return jsonDecode(contenido);
    } catch (e) {
      return [];
    }
  }

  // Registrar un nuevo usuario en el JSON
  static Future<bool> registrarUsuario(String usuario, String password) async {
    final usuarios = await obtenerUsuarios();

    // Verificar si el usuario ya existe
    bool existe = usuarios.any((u) => u['usuario'] == usuario);
    if (existe) return false;

    // Agregar el nuevo usuario con contraseña hasheada
    usuarios.add({
      'usuario': usuario,
      'password': hashPassword(password),
    });

    final file = await _getFile();
    await file.writeAsString(jsonEncode(usuarios));
    return true;
  }

  // Validar credenciales desde el JSON
  static Future<bool> validarLogin(String usuario, String password) async {
    final usuarios = await obtenerUsuarios();
    final passwordHash = hashPassword(password);

    return usuarios.any((u) =>
        u['usuario'] == usuario && u['password'] == passwordHash);
  }
}

// ---------------------------------------------------------------------------
// PANTALLA DE LOGIN
// ---------------------------------------------------------------------------
class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usuario = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _usuario.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (_formKey.currentState!.validate()) {
      bool valido = await JsonAuthService.validarLogin(
        _usuario.text.trim(),
        _password.text.trim(),
      );

      if (!mounted) return;

      if (valido) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Inicio()),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.error_outline, size: 64, color: Colors.red),
            title: const Text('Error de acceso'),
            content: const Text(
              'Usuario o contraseña incorrectos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Intentar de nuevo'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Logo', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mi App',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 48),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 12.0),
                        child: Text('User: ', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _usuario,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'User',
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Ingresa un usuario' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 12.0),
                        child: Text('Password: ', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '******',
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Ingresa la contraseña' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                    onPressed: _iniciarSesion,
                    child: const Text(
                      'Entrar',
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botón para ir al Registro
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PantallaRegistro(),
                        ),
                      );
                    },
                    child: const Text(
                      '¿No tienes cuenta? Regístrate aquí',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PANTALLA DE REGISTRO
// ---------------------------------------------------------------------------
class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usuario = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _usuario.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_formKey.currentState!.validate()) {
      bool exito = await JsonAuthService.registrarUsuario(
        _usuario.text.trim(),
        _password.text.trim(),
      );

      if (!mounted) return;

      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Usuario registrado con éxito en JSON!')),
        );
        Navigator.pop(context); // Volver al login
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.warning, size: 64, color: Colors.orange),
            title: const Text('Registro Fallido'),
            content: const Text('El nombre de usuario ya se encuentra registrado.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Registro',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 12.0),
                        child: Text('User: ', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _usuario,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Nuevo Usuario',
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Crea un usuario' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 12.0),
                        child: Text('Password: ', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '******',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Crea una contraseña';
                            }
                            if (value.length < 4) {
                              return 'Mínimo 4 caracteres';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                    onPressed: _registrar,
                    child: const Text(
                      'Registrar',
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '¿Ya tienes cuenta? Inicia sesión',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NAVEGACIÓN PRINCIPAL
// ---------------------------------------------------------------------------
class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  int _pestana = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _pestana,
        children: const [
          PantallaHola(),
          PantallaContador(),
          PantallaCupertino(),
          PantallaCRUD(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: (i) => setState(() => _pestana = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Hola'),
          NavigationDestination(icon: Icon(Icons.touch_app), label: 'Contador'),
          NavigationDestination(
              icon: Icon(Icons.phone_iphone), label: 'Cupertino'),
          NavigationDestination(
              icon: Icon(Icons.storage), label: 'Datos (CRUD)'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MODELO Y HELPER DE BASE DE DATOS SQLITE (CRUD)
// ---------------------------------------------------------------------------
class Reporte {
  final int? id;
  final String titulo;

  Reporte({this.id, required this.titulo});

  Map<String, dynamic> toMap() {
    return {'id': id, 'titulo': titulo};
  }

  factory Reporte.fromMap(Map<String, dynamic> map) {
    return Reporte(id: map['id'], titulo: map['titulo']);
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = p.join(await getDatabasesPath(), 'reportes.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reportes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titulo TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertReporte(Reporte reporte) async {
    Database db = await database;
    return await db.insert('reportes', reporte.toMap());
  }

  Future<List<Reporte>> getReportes() async {
    Database db = await database;
    var res = await db.query('reportes');
    return res.isNotEmpty ? res.map((c) => Reporte.fromMap(c)).toList() : [];
  }

  Future<int> updateReporte(Reporte reporte) async {
    Database db = await database;
    return await db.update('reportes', reporte.toMap(),
        where: 'id = ?', whereArgs: [reporte.id]);
  }

  Future<int> deleteReporte(int id) async {
    Database db = await database;
    return await db.delete('reportes', where: 'id = ?', whereArgs: [id]);
  }
}

// ---------------------------------------------------------------------------
// PANTALLAS SECUNDARIAS
// ---------------------------------------------------------------------------
class PantallaCRUD extends StatefulWidget {
  const PantallaCRUD({super.key});

  @override
  State<PantallaCRUD> createState() => _PantallaCRUDState();
}

class _PantallaCRUDState extends State<PantallaCRUD> {
  final dbHelper = DatabaseHelper();
  List<Reporte> reportes = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final datos = await dbHelper.getReportes();
    setState(() => reportes = datos);
  }

  void _mostrarDialogo({Reporte? reporteActual}) {
    final TextEditingController tituloCtrl =
        TextEditingController(text: reporteActual?.titulo ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reporteActual == null ? 'Nuevo Registro' : 'Editar Registro'),
        content: TextField(
          controller: tituloCtrl,
          decoration: const InputDecoration(labelText: 'Título'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (tituloCtrl.text.isNotEmpty) {
                if (reporteActual == null) {
                  await dbHelper.insertReporte(Reporte(titulo: tituloCtrl.text));
                } else {
                  await dbHelper.updateReporte(Reporte(
                      id: reporteActual.id, titulo: tituloCtrl.text));
                }
                _cargarDatos();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Base de Datos (CRUD)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: reportes.isEmpty
          ? const Center(child: Text('No hay registros. Toca + para añadir.'))
          : ListView.builder(
              itemCount: reportes.length,
              itemBuilder: (context, index) {
                final reporte = reportes[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${reporte.id}')),
                  title: Text(reporte.titulo),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _mostrarDialogo(reporteActual: reporte),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await dbHelper.deleteReporte(reporte.id!);
                          _cargarDatos();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogo(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PantallaHola extends StatefulWidget {
  const PantallaHola({super.key});

  @override
  State<PantallaHola> createState() => _PantallaHolaState();
}

class _PantallaHolaState extends State<PantallaHola>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nombre = TextEditingController();
  bool _marcado = false;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  late final Animation<double> _flota = Tween<double>(begin: -14, end: 14)
      .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));

  @override
  void dispose() {
    _anim.dispose();
    _nombre.dispose();
    super.dispose();
  }

  void _irAFrase() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaginaFrase(nombre: _nombre.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text('Hola', style: TextStyle(fontSize: 40)),
                  AnimatedBuilder(
                    animation: _flota,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _flota.value),
                        child: Transform.rotate(
                          angle: _flota.value * 0.005,
                          child: child,
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/images/logo_sre.png',
                      width: 220,
                      height: 220,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.assignment_turned_in,
                        size: 120,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text('Nombre:', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _nombre,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          Checkbox(
                            value: _marcado,
                            onChanged: (valor) =>
                                setState(() => _marcado = valor ?? false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _irAFrase,
                        child: const Text('Ver frase'),
                      ),
                    ],
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const Text(
                        'Texto de abajo',
                        style: TextStyle(fontSize: 60, color: Colors.grey),
                      ),
                      const Text(
                        'Texto de arriba',
                        style: TextStyle(fontSize: 24, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PaginaFrase extends StatelessWidget {
  final String nombre;

  const PaginaFrase({super.key, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Frase del día')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.format_quote, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Cada gran app empezó con una pantalla en blanco.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontStyle: FontStyle.italic),
              ),
              if (nombre.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Para ti, $nombre',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PantallaContador extends StatefulWidget {
  const PantallaContador({super.key});

  @override
  State<PantallaContador> createState() => _PantallaContadorState();
}

class _PantallaContadorState extends State<PantallaContador> {
  final TextEditingController _texto =
      TextEditingController(text: 'Contador+AfectaAlgo');
  int _contador = 0;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double tamano = (24 + _contador * 2).clamp(24, 48).toDouble();

    return SizedBox.expand(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF0000),
              Color(0xFFFF9800),
              Color(0xFFFFEB3B),
              Color(0xFF00E000),
              Color(0xFF0000FF),
              Color(0xFF8E24AA),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _texto,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => setState(() => _contador++),
                  child: const Text('Prueba'),
                ),
                const SizedBox(height: 24),
                Text(
                  _texto.text.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: tamano,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Presionado: $_contador veces',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PantallaCupertino extends StatefulWidget {
  const PantallaCupertino({super.key});

  @override
  State<PantallaCupertino> createState() => _PantallaCupertinoState();
}

class _PantallaCupertinoState extends State<PantallaCupertino> {
  final TextEditingController _usuario = TextEditingController();

  @override
  void dispose() {
    _usuario.dispose();
    super.dispose();
  }

  void _mostrarAlerta() {
    final nombre = _usuario.text.trim();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Lo de hoy'),
        content: Text(
          nombre.isEmpty
              ? 'Escribe un usuario primero'
              : 'Hola, $nombre. Esto es Cupertino + una alerta + un Stack',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4CE000),
                    Color(0xFF1E90FF),
                    Color(0xFF3F51B5),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            top: 70,
            left: 24,
            child: Icon(Icons.emoji_emotions,
                size: 130, color: Color(0xFFFFEB3B)),
          ),
          const Positioned(
            top: 100,
            right: 24,
            child: Icon(Icons.waving_hand,
                size: 90, color: Color(0xFFFFB74D)),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoTextField(
                    controller: _usuario,
                    placeholder: 'Username',
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: _mostrarAlerta,
                    child: const Text('Entrar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}