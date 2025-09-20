#!/bin/bash

# Путь к .app
APP_PATH="build/ios/iphoneos/Runner.app"

# Проверка на наличие .app
if [ ! -d "$APP_PATH" ]; then
  echo "❌ .app файл не найден по пути: $APP_PATH"
  exit 1
fi

# Создание Payload и .ipa
echo "📦 Создание Payload..."
cd build/ios/iphoneos
rm -rf Payload
mkdir Payload
cp -r Runner.app Payload/

echo "📦 Упаковка в Runner.ipa..."
zip -r Runner.ipa Payload > /dev/null

# Очистка (опционально)
rm -rf Payload

echo "✅ IPA-файл создан: build/ios/iphoneos/Runner.ipa"