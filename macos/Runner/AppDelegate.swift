import Cocoa
import FlutterMacOS

// Используем современную аннотацию вместо устаревшей @NSApplicationMain
@main
class AppDelegate: FlutterAppDelegate {
  // Переменная для канала связи между Swift и Flutter
  private var methodChannel: FlutterMethodChannel?
  
  // Корректная реализация applicationSupportsSecureRestorableState
  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  // Переменная для хранения контроллера Flutter
  private var flutterViewController: FlutterViewController? {
    // В macOS нет FlutterWindowController, используем прямой доступ
    // к контроллеру через NSApp.mainWindow
    return NSApp.mainWindow?.contentViewController as? FlutterViewController
  }
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Вызываем метод суперкласса, чтобы настроить Flutter
    super.applicationDidFinishLaunching(notification)
    
    // После того, как Flutter инициализирован, получаем контроллер и настраиваем канал
    if let controller = flutterViewController {
      setupMethodChannel(controller: controller)
    }
    
    // Регистрируем обработчик URL схемы (для обработки deep links)
    NSAppleEventManager.shared().setEventHandler(
      self,
      andSelector: #selector(handleURLEvent(_:withReply:)),
      forEventClass: AEEventClass(kInternetEventClass),
      andEventID: AEEventID(kAEGetURL)
    )
    
    print("AppDelegate: URL handler registered for io.supabase.pointo scheme")
  }
  
  // Обработка открытия приложения по URL схеме
  override func applicationWillFinishLaunching(_ notification: Notification) {
    // Вызовем сначала метод суперкласса
    super.applicationWillFinishLaunching(notification)
    
    // Зарегистрируем приложение как обработчик схемы URL
    let appleEventManager = NSAppleEventManager.shared()
    appleEventManager.setEventHandler(
      self,
      andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
      forEventClass: AEEventClass(kInternetEventClass),
      andEventID: AEEventID(kAEGetURL)
    )
  }
  
  // Настраиваем метод-канал для коммуникации с Flutter
  private func setupMethodChannel(controller: FlutterViewController) {
    // Создаем канал с именем 'custom_link_channel'
    methodChannel = FlutterMethodChannel(
      name: "custom_link_channel",
      binaryMessenger: controller.engine.binaryMessenger
    )
    
    // Добавляем обработчик для вызовов из Flutter
    methodChannel?.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "testChannel" {
        // Отвечаем на тестовый запрос
        print("AppDelegate: Received testChannel call from Flutter")
        result("Channel is working!")
      } else {
        // Для других методов говорим, что они не реализованы
        result(FlutterMethodNotImplemented)
      }
    }
    
    print("AppDelegate: Method channel setup completed")
  }
  
  // Обработчик для URL схемы
  @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
    // Получаем URL из события
    guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue else {
      print("AppDelegate: Failed to get URL from event")
      return
    }
    
    print("AppDelegate: Received URL: \(urlString)")
    
    // Передаем URL во Flutter
    handleIncomingURL(urlString)
  }
  
  @objc private func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
    guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue else {
      return
    }
    
    print("AppDelegate: Received URL event: \(urlString)")
    
    // Обрабатываем полученный URL
    if let url = URL(string: urlString) {
      if url.scheme?.lowercased() == "io.supabase.pointo" {
        handleIncomingURL(url.absoluteString)
      }
    }
  }
  
  // Вспомогательный метод для обработки входящего URL
  private func handleIncomingURL(_ urlString: String) {
    guard let controller = flutterViewController else {
      print("AppDelegate: FlutterViewController not available")
      return
    }
    
    // Если канал еще не был создан, создаем его
    if methodChannel == nil {
      setupMethodChannel(controller: controller)
    }
    
    // Инвокация метода во Flutter
    methodChannel?.invokeMethod("onDeepLink", arguments: urlString)
    print("AppDelegate: URL sent to Flutter via method channel")
  }
  
  // Дополнительный метод для macOS для обработки открытия URL
  func application(_ application: NSApplication, openURLs urls: [URL]) {
    print("AppDelegate: openURLs called with \(urls)")
    for url in urls {
      if url.scheme?.lowercased() == "io.supabase.pointo" {
        handleIncomingURL(url.absoluteString)
      }
    }
  }
}