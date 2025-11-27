/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import 'dart:html' as html;
import 'package:transmit_client/transmit.dart';

Transmit? transmit;
dynamic subscription;

void main() {
  // Set up button event listeners
  final connectBtn = html.document.getElementById('connectBtn') as html.ButtonElement?;
  final disconnectBtn = html.document.getElementById('disconnectBtn') as html.ButtonElement?;
  final triggerBtn = html.document.getElementById('triggerBtn') as html.ButtonElement?;
  final clearBtn = html.document.getElementById('clearBtn') as html.ButtonElement?;
  
  connectBtn?.onClick.listen((e) => connect());
  disconnectBtn?.onClick.listen((e) => disconnect());
  triggerBtn?.onClick.listen((e) => triggerEvent());
  clearBtn?.onClick.listen((e) => clearMessages());
  
  // Auto-connect on page load
  connect();
}

void connect() {
  if (transmit != null) {
    addMessage('Already connected', 'info');
    return;
  }

  updateStatus('connecting', 'Connecting...');
  final connectBtn = html.document.getElementById('connectBtn') as html.ButtonElement?;
  final disconnectBtn = html.document.getElementById('disconnectBtn') as html.ButtonElement?;
  final triggerBtn = html.document.getElementById('triggerBtn') as html.ButtonElement?;
  
  connectBtn?.disabled = true;

  transmit = Transmit(TransmitOptions(
    baseUrl: 'http://localhost:3333',
    maxReconnectAttempts: 5,
    onReconnectAttempt: (attempt) {
      addMessage('Reconnect attempt $attempt', 'warning');
    },
    onReconnectFailed: () {
      addMessage('Reconnect failed', 'error');
      updateStatus('disconnected', 'Disconnected');
    },
  ));

  // Update UID display
  final uidElement = html.document.getElementById('uid');
  if (uidElement != null) {
    uidElement.text = transmit!.uid;
  }

  // Listen to connection events
  transmit!.on('connected', () {
    updateStatus('connected', 'Connected');
    connectBtn?.disabled = true;
    disconnectBtn?.disabled = false;
    triggerBtn?.disabled = false;
    addMessage('Connected to server', 'success');
  });

  transmit!.on('disconnected', () {
    updateStatus('disconnected', 'Disconnected');
    connectBtn?.disabled = false;
    disconnectBtn?.disabled = true;
    triggerBtn?.disabled = true;
    addMessage('Disconnected from server', 'error');
  });

  transmit!.on('reconnecting', () {
    updateStatus('connecting', 'Reconnecting...');
    addMessage('Reconnecting...', 'warning');
  });

  // Create subscription
  subscription = transmit!.subscription('test');

  // Register message handler
  subscription.onMessage((message) {
    addMessage('Message received: ${message.toString()}', 'message');
  });

  // Create subscription on server
  subscription.create().then((_) {
    addMessage('Subscription created for channel: test', 'success');
  }).catchError((error) {
    addMessage('Failed to create subscription: $error', 'error');
  });
}

void disconnect() {
  if (transmit == null) {
    return;
  }

  subscription?.delete();
  transmit?.close();
  transmit = null;
  subscription = null;

  updateStatus('disconnected', 'Disconnected');
  final connectBtn = html.document.getElementById('connectBtn') as html.ButtonElement?;
  final disconnectBtn = html.document.getElementById('disconnectBtn') as html.ButtonElement?;
  final triggerBtn = html.document.getElementById('triggerBtn') as html.ButtonElement?;
  
  connectBtn?.disabled = false;
  disconnectBtn?.disabled = true;
  triggerBtn?.disabled = true;

  addMessage('Disconnected', 'info');
}

void triggerEvent() {
  html.HttpRequest.request(
    'http://localhost:3333/test',
    method: 'GET',
  ).then((request) {
    if (request.status == 200) {
      addMessage('Test event triggered', 'success');
    } else {
      addMessage('Failed to trigger event: ${request.status}', 'error');
    }
  }).catchError((error) {
    addMessage('Error triggering event: $error', 'error');
  });
}

void clearMessages() {
  final messagesDiv = html.document.getElementById('messages');
  if (messagesDiv != null) {
    messagesDiv.innerHtml = '';
  }
}

void updateStatus(String status, String text) {
  final statusDiv = html.document.getElementById('status');
  if (statusDiv != null) {
    statusDiv.className = 'status $status';
    statusDiv.text = text;
  }
}

void addMessage(String message, String type) {
  final messagesDiv = html.document.getElementById('messages');
  if (messagesDiv == null) return;

  final messageDiv = html.DivElement()
    ..className = 'message'
    ..innerHtml = '''
      <div class="message-time">${DateTime.now().toLocal().toString().substring(11, 19)}</div>
      <div class="message-content">$message</div>
    ''';

  messagesDiv.insertAdjacentElement('afterbegin', messageDiv);

  // Auto-scroll to top
  messagesDiv.scrollTop = 0;
}
