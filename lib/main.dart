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
      title: 'Galileo Flutter Side-by-Side',
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
  // Visibility state for each map panel
  bool showLeftMap = true;
  bool showRightMap = true;

  // Layer configs for each panel
  String _leftLayerString = 'osm_tile_layer';
  String _rightLayerString = 'osm_tile_layer';
  LayerConfig _leftLayerConfig = LayerConfig.osm();
  LayerConfig _rightLayerConfig = LayerConfig.osm();

  void _onViewportChanged(MapViewport viewport) {}
  void _onMapTap(double x, double y) {}

  Future<void> _changeLayer(bool isLeft, String? value) async {
    if (value == null) return;

    setState(() {
      if (isLeft) {
        _leftLayerString = value;
      } else {
        _rightLayerString = value;
      }
    });

    LayerConfig newConfig;

    switch (value) {
      case 'osm_tile_layer':
        newConfig = LayerConfig.osm();
      case 'vector_tile_layer_1':
        final style = await rootBundle.loadString("assets/vt_style.json");
        newConfig = LayerConfig.vectorTiles(
          urlTemplate: MAP_TILER_URL_TEMPLATE,
          styleJson: style,
        );
      case 'vector_tile_layer_2':
        final style = await rootBundle.loadString("assets/simple_style.json");
        newConfig = LayerConfig.vectorTiles(
          urlTemplate: MAP_TILER_URL_TEMPLATE,
          styleJson: style,
        );
      default:
        return;
    }

    if (mounted) {
      setState(() {
        if (isLeft) {
          _leftLayerConfig = newConfig;
        } else {
          _rightLayerConfig = newConfig;
        }
      });
    }
  }

  void _restoreMap(bool isLeft) {
    setState(() {
      if (isLeft) {
        showLeftMap = true;
        _leftLayerString = 'osm_tile_layer';
        _leftLayerConfig = LayerConfig.osm();
      } else {
        showRightMap = true;
        _rightLayerString = 'osm_tile_layer';
        _rightLayerConfig = LayerConfig.osm();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galileo Flutter — Side-by-Side Maps'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // ── Top toolbar ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey[100],
            child: Row(
              children: [
                // Left map controls
                Expanded(child: _MapToolbar(
                  label: 'Left Map',
                  alive: showLeftMap,
                  layerValue: _leftLayerString,
                  onLayerChanged: (v) => _changeLayer(true, v),
                  onDispose: showLeftMap
                      ? () => setState(() => showLeftMap = false)
                      : null,
                  onRestore: !showLeftMap
                      ? () => _restoreMap(true)
                      : null,
                )),

                const VerticalDivider(width: 24, thickness: 1),

                // Right map controls
                Expanded(child: _MapToolbar(
                  label: 'Right Map',
                  alive: showRightMap,
                  layerValue: _rightLayerString,
                  onLayerChanged: (v) => _changeLayer(false, v),
                  onDispose: showRightMap
                      ? () => setState(() => showRightMap = false)
                      : null,
                  onRestore: !showRightMap
                      ? () => _restoreMap(false)
                      : null,
                )),
              ],
            ),
          ),

          // ── Map panels ────────────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left panel
                Expanded(
                  child: _MapPanel(
                    label: 'Left Map',
                    mapKey: const ValueKey('mapLeft'),
                    alive: showLeftMap,
                    layerConfig: _leftLayerConfig,
                    onViewportChanged: _onViewportChanged,
                    onTap: _onMapTap,
                  ),
                ),

                const VerticalDivider(width: 2, thickness: 2),

                // Right panel
                Expanded(
                  child: _MapPanel(
                    label: 'Right Map',
                    mapKey: const ValueKey('mapRight'),
                    alive: showRightMap,
                    layerConfig: _rightLayerConfig,
                    onViewportChanged: _onViewportChanged,
                    onTap: _onMapTap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toolbar widget for each map panel ─────────────────────────────────────────

class _MapToolbar extends StatelessWidget {
  const _MapToolbar({
    required this.label,
    required this.alive,
    required this.layerValue,
    required this.onLayerChanged,
    this.onDispose,
    this.onRestore,
  });

  final String label;
  final bool alive;
  final String layerValue;
  final ValueChanged<String?> onLayerChanged;
  final VoidCallback? onDispose;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(width: 8),

        // Layer selector — only useful while the map is alive
        if (alive)
          DropdownButton<String>(
            value: layerValue,
            onChanged: onLayerChanged,
            items: const [
              DropdownMenuItem(
                value: 'osm_tile_layer',
                child: Text('OSM Tiles', style: TextStyle(fontSize: 12)),
              ),
              DropdownMenuItem(
                value: 'vector_tile_layer_1',
                child: Text('Vector Style 1', style: TextStyle(fontSize: 12)),
              ),
              DropdownMenuItem(
                value: 'vector_tile_layer_2',
                child: Text('Vector Style 2', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),

        const Spacer(),

        // Dispose / Restore button
        if (alive)
          ElevatedButton.icon(
            onPressed: onDispose,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Dispose', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: onRestore,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Restore', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
      ],
    );
  }
}

// ── Map panel widget ───────────────────────────────────────────────────────────

class _MapPanel extends StatelessWidget {
  const _MapPanel({
    required this.label,
    required this.mapKey,
    required this.alive,
    required this.layerConfig,
    required this.onViewportChanged,
    required this.onTap,
  });

  final String label;
  final ValueKey mapKey;
  final bool alive;
  final LayerConfig layerConfig;
  final void Function(MapViewport) onViewportChanged;
  final void Function(double, double) onTap;

  @override
  Widget build(BuildContext context) {
    if (!alive) {
      // Placeholder shown when the map has been disposed
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                '$label disposed',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Use the Restore button above to bring it back.',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
      child: GalileoMapWidget.fromConfig(
        key: mapKey,
        size: const MapSize(width: 800, height: 600),
        layers: [layerConfig],
        config: MapInitConfig(
          backgroundColor: (0.1, 0.1, 0, 0.5),
          enableMultisampling: true,
          latlon: (0.0, 0.0),
          mapSize: MapSize(width: 800, height: 600),
          zoomLevel: 10,
        ),
        enableKeyboard: true,
        onTap: onTap,
        onViewportChanged: onViewportChanged,
        child: Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
