# 🛠️ Zoho Cliq Setup Guide

Step-by-step instructions to set up Zoho Cliq integration.

---

## Prerequisites

- Zoho account with Cliq access
- Tasker Backend deployed and running
- API key configured in environment

---

## Step 1: Create Cliq Extension

1. Go to [Zoho Cliq Developer Console](https://cliq.zoho.com/developer)
2. Click **Create Extension**
3. Fill in details:
   - Name: `Tasker`
   - Description: `Task management for Zoho Cliq`
   - Category: `Productivity`

---

## Step 2: Configure Commands

### Add Slash Command

1. In extension settings, go to **Commands**
2. Click **Add Command**
3. Configure:
   - Name: `tasker`
   - Description: `Manage your tasks`
   - Handler Type: `HTTP Webhook`
   - Webhook URL: `{YOUR_BACKEND_URL}/api/cliq/command`

### Command Parameters
```
/tasker [action] [arguments]

Actions:
  list          - List tasks
  add [title]   - Create task
  project [id]  - Show project tasks
  stats         - Show statistics
```

---

## Step 3: Configure Bot

1. Go to **Bots** in extension settings
2. Click **Add Bot**
3. Configure:
   - Name: `TaskerBot`
   - Display Name: `Tasker Bot`
   - Webhook Handler: `{YOUR_BACKEND_URL}/api/cliq/bot`

### Bot Capabilities
- Message handler
- Welcome message
- Action buttons

---

## Step 4: Configure Widget

1. Go to **Widgets** in extension settings
2. Click **Add Widget**
3. Configure:
   - Name: `tasker_home`
   - Type: `Home Widget`
   - Handler URL: `{YOUR_BACKEND_URL}/api/cliq/widget`

---

## Step 5: Link User Accounts

Users must link their Cliq and Tasker accounts:

### In Flutter App
1. Navigate to Settings > Integrations
2. Tap "Connect Zoho Cliq"
3. Enter Cliq User ID
4. Confirm connection

### API Endpoint
```
POST /api/cliq/link
{
  "taskerId": "firebase-user-id",
  "cliqUserId": "cliq-user-id"
}
```

---

## Step 6: Test Integration

### Test Slash Command
In any Cliq channel:
```
/tasker list
```

### Test Bot
Direct message TaskerBot:
```
show my tasks
```

### Test Widget
Check Home tab for Tasker widget.

---

## Environment Variables

Required in Tasker Backend:

```env
# Cliq Configuration
CLIQ_WEBHOOK_TOKEN=your-webhook-token
CLIQ_CLIENT_ID=your-client-id
CLIQ_CLIENT_SECRET=your-client-secret

# Backend
API_KEY=your-api-key
```

---

## Troubleshooting

### Command Not Responding
1. Check backend is running
2. Verify webhook URL is correct
3. Check API key is configured
4. Review backend logs

### User Not Linked
1. Verify user mapping in Firebase
2. Check `cliq_user_mappings` collection
3. Re-link account if needed

### Widget Not Loading
1. Check widget handler URL
2. Verify CORS settings
3. Review network requests

---

## Security

- All webhooks require authentication
- API key validated on each request
- User mappings stored in Firebase
- HTTPS required for all endpoints

---

## Next Steps

- [Slash Commands Reference](./slash-commands.md)
- [Bot & Widgets Guide](./bot-widgets.md)
- [Backend Documentation](../../Tasker%20Backend/README.md)

---

<div align="center">

**[← Overview](./overview.md)** | **[Slash Commands →](./slash-commands.md)**

</div>
