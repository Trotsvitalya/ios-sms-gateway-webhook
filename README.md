# SMS Gateway for iOS (TrollStore)

[![Build & Release IPA](https://github.com/Trotsvitalya/ios-sms-gateway-webhook/actions/workflows/build.yml/badge.svg)](https://github.com/Trotsvitalya/ios-sms-gateway-webhook/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![iOS 15-16](https://img.shields.io/badge/iOS-15--16-orange.svg)](https://github.com/Trotsvitalya/ios-sms-gateway-webhook)
[![TrollStore](https://img.shields.io/badge/Platform-TrollStore-green.svg)](https://github.com/opa334/TrollStore)

An open-source, background SMS-to-Webhook forwarding utility for iOS 15.0 – 16.6.1 with TrollStore.

---

## 🌐 Language / Мова
* [English](#english)
* [Українська](#українська)

---

<a name="english"></a>
## 🇬🇧 English

### Overview
This application monitors incoming SMS and iMessage events in real-time from the local iOS database (`/var/mobile/Library/SMS/sms.db`) and forwards them to your configured HTTP(S) Webhooks or Telegram Bot endpoints.

### Features
* **Flexible Forwarding Rules:**
  * Sender filter (specific number, sender name, or `*` for all messages).
  * Regular Expression (**RegEx**) matching for senders.
  * Message body substring filtering.
* **Custom Webhook Payloads:**
  * Configurable JSON templates (`%from%`, `%text%`, `%sentStamp%`, `%receivedStamp%`, `%sim%`).
  * Custom HTTP headers support (e.g., `Authorization: Bearer <token>`).
* **Persistent Background Execution:**
  * Runs 24/7 without being suspended by iOS memory management.
* **Live History & Delivery Logs:**
  * Real-time inspection of forwarded SMS and HTTP response codes.
* **One-tap Test Dispatch:**
  * Verify your webhook destination with dummy data.

### Installation via TrollStore
1. Download `SMSGateway.ipa` from the [Latest Release](https://github.com/Trotsvitalya/ios-sms-gateway-webhook/releases).
2. Open the file on your device and choose **Share → TrollStore**.
3. Tap **Install**.
4. Launch the app, verify the database indicator is **Connected**, and toggle **Service Active**.

---

<a name="українська"></a>
## 🇺🇦 Українська

### Огляд
Додаток відстежує вхідні SMS та iMessage у реальному часі безпосередньо з системної бази (`/var/mobile/Library/SMS/sms.db`) та миттєво пересилає їх на ваші HTTP(S) вебхуки або в Telegram-бота.

### Основні можливості
* **Гнучкі правила пересилання:**
  * Фільтрація за номером, назвою або `*` (для всіх).
  * Підтримка регулярних виразів (**RegEx**).
  * Фільтрація за текстом повідомлення.
* **Налаштування Webhook:**
  * Довільні JSON-шаблони тіла запиту.
  * Підтримка кастомних HTTP-заголовків.
* **Безперервна робота 24/7:**
  * Працює у фоновому режимі під TrollStore без вивантаження системою.
* **Журнал та перевірка доставки:**
  * Відображення отриманих повідомлень та HTTP-статусів відповіді сервера.
* **Тестове відправлення:**
  * Перевірка підключення до Telegram або Webhook в один клік.

### Встановлення
1. Завантажте `SMSGateway.ipa` з вкладки [Releases](https://github.com/Trotsvitalya/ios-sms-gateway-webhook/releases).
2. Натисніть **Поділитися → TrollStore**.
3. Натисніть **Install**.
4. Відкрийте додаток, додайте правило та увімкніть перемикач **Сервіс активний**.

---

## 🙏 Acknowledgments / Подяка

Special thanks to **Konstantin Bogomolov** ([@bogkonstantin](https://github.com/bogkonstantin)) for the original Android application [android_income_sms_gateway_webhook](https://github.com/bogkonstantin/android_income_sms_gateway_webhook), which inspired this iOS version.

Окрема подяка **Костянтину Богомолову** ([@bogkonstantin](https://github.com/bogkonstantin)) за оригінальний Android-додаток [android_income_sms_gateway_webhook](https://github.com/bogkonstantin/android_income_sms_gateway_webhook), концепція якого лягла в основу цієї версії для iOS.

---

## 📄 License
This project is licensed under the [MIT License](LICENSE).
