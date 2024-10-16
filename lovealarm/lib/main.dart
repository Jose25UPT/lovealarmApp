import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

void main() => runApp(LoveAlarmApp());

class LoveAlarmApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Love Alarm',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: HomePage(),
    );
  }
}

class NearbyUser {
  final String id;
  final String name;
  final String imageUrl;
  final double distance;

  NearbyUser({required this.id, required this.name, required this.imageUrl, required this.distance});
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  bool _keepActiveWhenOff = false;
  late AnimationController _animationController;
  List<NearbyUser> _nearbyUsers = [];
  Color _backgroundColor = Colors.pink[100]!;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadPreferences();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();
    _simulateNearbyUsers();
  }

  void _simulateNearbyUsers() {
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _nearbyUsers = List.generate(
            5,
            (index) => NearbyUser(
              id: 'user$index',
              name: 'Usuario ${index + 1}',
              imageUrl: 'https://picsum.photos/seed/$index/200',
              distance: (index + 1) * 10.0,
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Permisos de localización denegados');
      }
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _keepActiveWhenOff = prefs.getBool('keepActiveWhenOff') ?? false;
      _backgroundColor = Color(prefs.getInt('backgroundColor') ?? Colors.pink[100]!.value);
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keepActiveWhenOff', _keepActiveWhenOff);
    await prefs.setInt('backgroundColor', _backgroundColor.value);
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
    });
    if (_isSearching) {
      _simulateNearbyUsers();
    } else {
      setState(() {
        _nearbyUsers.clear();
      });
    }
  }

  void _toggleKeepActive(bool value) {
    setState(() {
      _keepActiveWhenOff = value;
    });
    _savePreferences();
  }

  void _showUserProfile(NearbyUser user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(user.imageUrl),
                radius: 50,
              ),
              SizedBox(height: 20),
              Text(user.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('${user.distance.toInt()} metros de distancia'),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Iniciar conversación'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChatPage(user: user)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Elige un color de fondo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                child: Text('Rosa'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[100]),
                onPressed: () => _changeBackgroundColor(Colors.pink[100]!),
              ),
              ElevatedButton(
                child: Text('Rojo'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[100]),
                onPressed: () => _changeBackgroundColor(Colors.red[100]!),
              ),
              ElevatedButton(
                child: Text('Púrpura'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[100]),
                onPressed: () => _changeBackgroundColor(Colors.purple[100]!),
              ),
            ],
          ),
        );
      },
    );
  }

  void _changeBackgroundColor(Color color) {
    setState(() {
      _backgroundColor = color;
    });
    _savePreferences();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('Love Alarm'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.location_on,
              color: _keepActiveWhenOff ? Colors.green : Colors.red,
              size: 30,
            ),
            onPressed: () => _toggleKeepActive(!_keepActiveWhenOff),
          ),
          IconButton(
            icon: Icon(Icons.color_lens),
            onPressed: _showColorPicker,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: WavePainter(
                        animation: _animationController,
                        isSearching: _isSearching,
                      ),
                      size: Size(300, 300),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.favorite : Icons.favorite_border,
                    size: 50,
                    color: Colors.red,
                  ),
                  onPressed: _toggleSearch,
                ),
                ..._buildNearbyUserAvatars(),
              ],
            ),
            SizedBox(height: 20),
            Text(
              _isSearching ? 'Buscando...' : 'Love Alarm desactivado',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNearbyUserAvatars() {
    return List.generate(_nearbyUsers.length, (index) {
      final user = _nearbyUsers[index];
      final angle = 2 * math.pi * index / _nearbyUsers.length;
      return Positioned(
        left: 150 + 120 * math.cos(angle),
        top: 150 + 120 * math.sin(angle),
        child: GestureDetector(
          onTap: () => _showUserProfile(user),
          child: CircleAvatar(
            backgroundImage: NetworkImage(user.imageUrl),
            radius: 20,
          ),
        ),
      );
    });
  }
}

class WavePainter extends CustomPainter {
  final Animation<double> animation;
  final bool isSearching;

  WavePainter({required this.animation, required this.isSearching}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (!isSearching) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;

    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < 3; i++) {
      final progress = (animation.value + i / 3) % 1.0;
      final radius = progress * maxRadius;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class ChatPage extends StatefulWidget {
  final NearbyUser user;

  ChatPage({required this.user});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<String> _messages = [];
  final TextEditingController _textController = TextEditingController();

  void _handleSubmitted(String text) {
    _textController.clear();
    setState(() {
      _messages.add(text);
    });
  }

  Widget _buildTextComposer() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: <Widget>[
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration.collapsed(hintText: "Enviar un mensaje"),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () => _handleSubmitted(_textController.text),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat con ${widget.user.name}'),
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) => Text(_messages[index]),
              itemCount: _messages.length,
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }
}