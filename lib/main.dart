import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:galileo_flutter/galileo_flutter.dart';

const MAP_TILER_API_KEY = '';
const MAP_TILER_URL_TEMPLATE =
    'https://api.maptiler.com/tiles/v3-openmaptiles/{z}/{x}/{y}.pbf?key=$MAP_TILER_API_KEY';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception is AssertionError &&
        details.exception.toString().contains('KeyDownEvent is dispatched')) {
      return;
    }
    FlutterError.dumpErrorToConsole(details);
  };

  await initGalileo();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Galileo Flutter Memory Leak Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const GalileoMapPage(),
    );
  }
}

class GalileoMapPage extends StatefulWidget {
  const GalileoMapPage({super.key});

  @override
  State<GalileoMapPage> createState() => _GalileoMapPageState();
}

class _GalileoMapPageState extends State<GalileoMapPage> {
  MapViewport? currentViewport;
  bool showWidget = true;
  bool isTestRunning = false;
  int cycleCount = 0;
  int targetCycles = 50; 

  void _onViewportChanged(MapViewport viewport) {}
  void _onMapTap(double x, double y) {}

  @override
  void initState() {
    super.initState();
  }

  void _startStressTest() async {
    if (isTestRunning) return;
    
    setState(() {
      isTestRunning = true;
      cycleCount = 0;
    });

    for (int i = 0; i < targetCycles; i++) {
      if (!mounted) break;
      
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (!mounted) break;
      setState(() {
        showWidget = !showWidget;
        cycleCount = i + 1;
      });
    }

    if (mounted) {
      setState(() => isTestRunning = false);
    }
  }

  void _stopStressTest() {
    setState(() {
      isTestRunning = false;
      targetCycles = cycleCount; // Stop at current count
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The map widget that gets toggled
          showWidget
              ? GalileoMapWidget.fromConfig(
                  key: const ValueKey("mapA"),
                  size: const MapSize(width: 800, height: 600),
                  layers: [_makeLayer()],
                  config: MapInitConfig(
                    backgroundColor: (0.1, 0.1, 0, 0.5),
                    enableMultisampling: true,
                    latlon: (0.0, 0.0),
                    mapSize: MapSize(width: 800, height: 600),
                    zoomLevel: 10,
                  ),
                  enableKeyboard: true,
                  onTap: _onMapTap,
                  onViewportChanged: _onViewportChanged,
                )
              : GalileoMapWidget.fromConfig(
                  key: const ValueKey("mapB"),
                  size: const MapSize(width: 800, height: 600),
                  layers: [_makeLayer()],
                  config: MapInitConfig(
                    backgroundColor: (0.1, 0.1, 0, 0.5),
                    enableMultisampling: true,
                    latlon: (0.0, 0.0),
                    mapSize: MapSize(width: 800, height: 600),
                    zoomLevel: 10,
                  ),
                  enableKeyboard: true,
                  onTap: _onMapTap,
                  onViewportChanged: _onViewportChanged,
                ),
          
          // Status overlay
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Memory Leak Test',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Cycles: $cycleCount / $targetCycles',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    'Status: ${isTestRunning ? "Running" : "Stopped"}',
                    style: TextStyle(
                      color: isTestRunning ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Current: ${showWidget ? "Map A" : "Map B"}',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: isTestRunning ? _stopStressTest : _startStressTest,
                    child: Text(isTestRunning ? 'Stop Test' : 'Restart Test'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LayerConfig _makeLayer() => LayerConfig.osm();

  @override
  void dispose() {
    isTestRunning = false;
    super.dispose();
  }
}
