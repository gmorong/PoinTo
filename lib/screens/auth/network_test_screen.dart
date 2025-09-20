import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NetworkTestScreen extends StatefulWidget {
  const NetworkTestScreen({Key? key}) : super(key: key);

  @override
  _NetworkTestScreenState createState() => _NetworkTestScreenState();
}

class _NetworkTestScreenState extends State<NetworkTestScreen> {
  bool _isLoading = false;
  Map<String, String> _testResults = {};
  String? _connectionStatus;

  final TextEditingController _urlController =
      TextEditingController(text: 'https://pyfpjkhoesrfxhoqlush.supabase.co');

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      if (connectivityResult == ConnectivityResult.mobile) {
        _connectionStatus = 'Mobile data';
      } else if (connectivityResult == ConnectivityResult.wifi) {
        _connectionStatus = 'WiFi';
      } else if (connectivityResult == ConnectivityResult.ethernet) {
        _connectionStatus = 'Ethernet';
      } else if (connectivityResult == ConnectivityResult.none) {
        _connectionStatus = 'No network connection';
      } else {
        _connectionStatus = 'Unknown';
      }
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _testResults = {};
    });

    try {
      String url = _urlController.text.trim();
      if (!url.startsWith('http')) {
        url = 'https://$url';
      }

      // Тест 1: HTTP GET запрос
      await _testHttpRequest(url);

      // Тест 2: Проверка DNS
      await _testDnsLookup(url);

      // Тест 3: Тест Socket соединения
      await _testSocketConnection(url);

      // Тест 4: Проверка SSL/TLS
      await _testSSLConnection(url);

      // Тест 5: Проверка Supabase API
      await _testSupabaseApi();

      // Тест 6: Проверка прокси/брандмауэра
      await _testProxySettings();
    } catch (e) {
      setState(() {
        _testResults['Error'] = 'Unexpected error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testHttpRequest(String url) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      setState(() {
        _testResults['HTTP Request'] =
            'Success: Status code ${response.statusCode}';
      });
    } catch (e) {
      setState(() {
        _testResults['HTTP Request'] = 'Failed: $e';
      });
    }
  }

  Future<void> _testDnsLookup(String url) async {
    try {
      Uri uri = Uri.parse(url);
      final host = uri.host;

      final List<InternetAddress> addresses = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 10));

      setState(() {
        _testResults['DNS Lookup'] =
            'Success: ${addresses.map((a) => a.address).join(', ')}';
      });
    } catch (e) {
      setState(() {
        _testResults['DNS Lookup'] = 'Failed: $e';
      });
    }
  }

  Future<void> _testSocketConnection(String url) async {
    try {
      Uri uri = Uri.parse(url);
      final host = uri.host;
      final port =
          uri.port != 0 ? uri.port : (uri.scheme == 'https' ? 443 : 80);

      final socket =
          await Socket.connect(host, port).timeout(const Duration(seconds: 10));

      socket.destroy();

      setState(() {
        _testResults['Socket Connection'] = 'Success: Connected to $host:$port';
      });
    } catch (e) {
      setState(() {
        _testResults['Socket Connection'] = 'Failed: $e';
      });
    }
  }

  Future<void> _testSSLConnection(String url) async {
    try {
      Uri uri = Uri.parse(url);
      if (uri.scheme != 'https') {
        setState(() {
          _testResults['SSL/TLS'] = 'Skipped: Not an HTTPS URL';
        });
        return;
      }

      final host = uri.host;
      final port = uri.port != 0 ? uri.port : 443;

      final socket = await SecureSocket.connect(host, port)
          .timeout(const Duration(seconds: 10));

      socket.destroy();

      setState(() {
        _testResults['SSL/TLS'] = 'Success: SSL handshake completed';
      });
    } catch (e) {
      setState(() {
        _testResults['SSL/TLS'] = 'Failed: $e';
      });
    }
  }

  Future<void> _testSupabaseApi() async {
    try {
      setState(() {
        _testResults['Supabase API'] = 'Тестирование...';
      });

      // Тест 1: Прямой HTTP запрос
      try {
        final http.Response response = await http.get(
          Uri.parse('${_urlController.text.trim()}/rest/v1/health'),
          headers: {'apikey': 'ваш_ключ_api'},
        ).timeout(const Duration(seconds: 10));

        setState(() {
          _testResults['Supabase HTTP'] =
              'Успех: Статус ${response.statusCode}, ${response.body}';
        });
      } catch (e) {
        setState(() {
          _testResults['Supabase HTTP'] = 'Ошибка: $e';
        });
      }

      // Тест 2: Клиент Supabase
      try {
        final client = Supabase.instance.client;

        // Вместо getSession используем метод из актуальной версии SDK
        final currentSession = client.auth.currentSession;

        if (currentSession != null) {
          setState(() {
            _testResults['Supabase Auth'] =
                'Успех: Сессия активна, ID пользователя: ${currentSession.user.id}';
          });
        } else {
          // Пробуем гостевой запрос к базе данных - обратите внимание на отсутствие execute()
          // ignore: unused_local_variable
          final response = await client
              .from('your_public_table') // Замените на имя существующей таблицы
              .select('count')
              .limit(1);

          setState(() {
            _testResults['Supabase API'] = 'Успех: API доступен, ответ получен';
          });
        }
      } catch (e) {
        setState(() {
          _testResults['Supabase API'] = 'Ошибка: $e';
        });
      }
    } catch (e) {
      setState(() {
        _testResults['Supabase API'] = 'Общая ошибка: $e';
      });
    }
  }

  Future<void> _testProxySettings() async {
    try {
      // Получаем данные об операционной системе
      final operatingSystem = Platform.operatingSystem;
      final operatingSystemVersion = Platform.operatingSystemVersion;

      // Проверяем наличие прокси
      final environment = Platform.environment;
      final httpProxy = environment['HTTP_PROXY'] ?? environment['http_proxy'];
      final httpsProxy =
          environment['HTTPS_PROXY'] ?? environment['https_proxy'];
      final noProxy = environment['NO_PROXY'] ?? environment['no_proxy'];

      String proxyInfo =
          'Operating System: $operatingSystem ($operatingSystemVersion)\n';

      if (httpProxy != null || httpsProxy != null) {
        proxyInfo += 'Proxy detected:\n';
        if (httpProxy != null) proxyInfo += 'HTTP_PROXY: $httpProxy\n';
        if (httpsProxy != null) proxyInfo += 'HTTPS_PROXY: $httpsProxy\n';
        if (noProxy != null) proxyInfo += 'NO_PROXY: $noProxy\n';
      } else {
        proxyInfo += 'No proxy detected in environment variables\n';
      }

      // На macOS проверяем настройки прокси через команду
      if (Platform.isMacOS) {
        try {
          final result =
              await Process.run('networksetup', ['-getwebproxy', 'Wi-Fi']);
          proxyInfo += '\nMacOS Proxy Configuration:\n${result.stdout}';
        } catch (e) {
          proxyInfo += '\nFailed to check macOS proxy settings: $e';
        }
      }

      setState(() {
        _testResults['Proxy Settings'] = proxyInfo;
      });
    } catch (e) {
      setState(() {
        _testResults['Proxy Settings'] = 'Failed to check: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Network Diagnostics'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Current connection: ${_connectionStatus ?? "Checking..."}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Supabase URL',
                border: OutlineInputBorder(),
                hintText: 'https://your-project.supabase.co',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Run Network Tests'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 24),
            if (_testResults.isNotEmpty) ...[
              Text(
                'Test Results:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ..._testResults.entries
                  .map((entry) => _buildTestResultCard(entry.key, entry.value)),
            ],
            SizedBox(height: 24),
            Text(
              'Troubleshooting Tips:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _buildTroubleshootingCard(
              title: 'Network Issues',
              content: '• Check your internet connection\n'
                  '• Try connecting to a different network\n'
                  '• Disable any VPN or proxy services\n'
                  '• Restart your modem/router',
            ),
            _buildTroubleshootingCard(
              title: 'Firewall/Proxy Issues',
              content: '• Check if your firewall is blocking the connection\n'
                  '• Ensure outbound connections to port 443 are allowed\n'
                  '• Check corporate proxy settings\n'
                  '• Temporarily disable your firewall for testing',
            ),
            _buildTroubleshootingCard(
              title: 'Supabase Configuration',
              content: '• Verify your Supabase URL and API key\n'
                  '• Check if your Supabase project is active\n'
                  '• Make sure your IP is not blocked in Supabase\n'
                  '• Check Supabase status page for service issues',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultCard(String test, String result) {
    bool isSuccess = result.startsWith('Success');

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  test,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(result),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingCard(
      {required String title, required String content}) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }
}
