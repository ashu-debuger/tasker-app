# 🔐 Environment Configuration

Tasker uses environment variables for secure configuration management.

---

## Overview

We use [`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv) to manage environment variables securely. This keeps sensitive data like API keys out of the codebase.

---

## Setup

### 1. Create Environment File

Copy the example file:

```bash
cp .env.example .env
```

### 2. Configure Variables

Edit `.env` with your values:

```env
# Backend API Configuration
TASKER_API_BASE_URL=https://your-backend-url/api
TASKER_API_KEY=your-secure-api-key
```

### 3. Never Commit `.env`

The `.env` file is already in `.gitignore`. Never commit it to version control.

---

## Available Variables

| Variable              | Description            | Required |
| --------------------- | ---------------------- | -------- |
| `TASKER_API_BASE_URL` | Backend API base URL   | ✅ Yes    |
| `TASKER_API_KEY`      | API authentication key | ✅ Yes    |

---

## Using EnvConfig

The `EnvConfig` class provides type-safe access to environment variables.

### Initialization

Called once in `main.dart`:

```dart
import 'package:tasker/src/core/config/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment configuration
  await EnvConfig.init();
  
  // Continue with app initialization...
}
```

### Accessing Values

Use the static getters:

```dart
import 'package:tasker/src/core/config/env_config.dart';

// Get API base URL
final baseUrl = EnvConfig.apiBaseUrl;

// Get API key
final apiKey = EnvConfig.apiKey;
```

### Example Usage

```dart
class CliqRepository {
  Future<void> linkCliqAccount(String userId) async {
    final response = await http.get(
      Uri.parse('${EnvConfig.apiBaseUrl}/cliq/link'),
      headers: {
        'x-api-key': EnvConfig.apiKey,
        'Content-Type': 'application/json',
      },
    );
  }
}
```

---

## EnvConfig Class

Located at `lib/src/core/config/env_config.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }

  static String get apiBaseUrl {
    final url = dotenv.env['TASKER_API_BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('TASKER_API_BASE_URL not configured in .env');
    }
    return url;
  }

  static String get apiKey {
    final key = dotenv.env['TASKER_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('TASKER_API_KEY not configured in .env');
    }
    return key;
  }
}
```

---

## Security Best Practices

### ✅ Do

- Keep `.env` in `.gitignore`
- Use `.env.example` for documentation
- Use different API keys per environment
- Rotate API keys periodically

### ❌ Don't

- Commit `.env` to version control
- Hardcode API keys in source code
- Share API keys in public channels
- Use production keys for development

---

## Environment-Specific Configuration

For different environments (dev, staging, prod), create multiple env files:

```
.env.development
.env.staging  
.env.production
```

Load the appropriate file:

```dart
await dotenv.load(fileName: '.env.${environment}');
```

---

## Troubleshooting

### Variables Not Loading

1. Ensure `.env` exists in project root
2. Check `pubspec.yaml` includes `.env` in assets:
   ```yaml
   flutter:
     assets:
       - .env
   ```
3. Verify `EnvConfig.init()` is called before accessing variables

### Missing Variable Error

If you get an exception about missing variables:
1. Check the variable exists in `.env`
2. Verify the variable name matches exactly
3. Ensure there are no typos

---

## Related Docs

- [Setup Guide](./setup-guide.md) - Complete setup instructions
- [Security](../security/encryption.md) - Security practices

---

<div align="center">

**[← Back to Docs](../README.md)** | **[Setup Guide →](./setup-guide.md)**

</div>
