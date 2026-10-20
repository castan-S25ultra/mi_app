import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
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
      home: const Inicio(),
    );
  }
}

// Contenedor principal: barra de navegación inferior para cambiar de pantalla
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
      // IndexedStack conserva lo escrito y el contador al cambiar de pestaña
      body: IndexedStack(
        index: _pestana,
        children: const [
          PantallaHola(),
          PantallaContador(),
          PantallaCupertino(),
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
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PANTALLA 1: "Hola" arriba, logo animado al centro, fila (etiqueta + campo +
// casilla), botón "Ver frase" debajo del campo y "Texto" abajo
// ---------------------------------------------------------------------------
class PantallaHola extends StatefulWidget {
  const PantallaHola({super.key});

  @override
  State<PantallaHola> createState() => _PantallaHolaState();
}

class _PantallaHolaState extends State<PantallaHola>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nombre = TextEditingController();
  bool _marcado = false;

  // Animación automática del logo: sube y baja sin parar (con un ligero giro)
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

  // Navega a otra página de la misma app
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

                  // Logo con movimiento automático (no hay que tocarlo)
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
                    // Si el archivo no se encuentra, muestra un ícono.
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

                  // Caja de texto y, justo debajo, el botón que abre otra página
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

// ---------------------------------------------------------------------------
// PÁGINA NUEVA: muestra una frase (y el nombre escrito, si lo hay)
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// PANTALLA 2: fondo de arcoíris, campo de texto, botón "Prueba" y texto en
// mayúsculas que refleja lo escrito. Cada clic agranda el texto.
// ---------------------------------------------------------------------------
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
    // El contador "afecta algo": el texto de abajo crece con cada clic (máx. 48)
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

// ---------------------------------------------------------------------------
// PANTALLA 3 (tarea de hoy): algo Cupertino + una alerta + un Stack
//  - Cupertino: CupertinoTextField, CupertinoButton y CupertinoAlertDialog
//  - Alerta:    showCupertinoDialog al presionar "Entrar"
//  - Stack:     capas apiladas (fondo, decoración y formulario encima)
// ---------------------------------------------------------------------------
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

  // Alerta estilo iOS
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
          // Capa 1: fondo degradado
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

          // Capa 2: decoración detrás del formulario
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

          // Capa 3: formulario estilo iOS, encima de todo
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