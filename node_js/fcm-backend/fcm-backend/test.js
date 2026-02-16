// Run: node test-notification.js YOUR_FCM_TOKEN

const http = require('http');

const token = process.argv[2];

if (!token) {
  console.log('❌ Usage: node test-notification.js YOUR_FCM_TOKEN');
  process.exit(1);
}

const data = JSON.stringify({
  token: token,
  title: '🔥 Test Notification',
  body: 'Push notification working successfully!',
});

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/send-notification',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(data),
  },
};

console.log('📤 Sending notification...');
console.log('📱 Token:', token.substring(0, 25) + '...');

const req = http.request(options, (res) => {
  let response = '';

  res.on('data', (chunk) => response += chunk);

  res.on('end', () => {
    console.log('Status:', res.statusCode);
    console.log('Response:', response);

    if (res.statusCode === 200) {
      console.log('✅ SUCCESS → Check your phone 🔔');
    } else {
      console.log('❌ FAILED');
    }
  });
});

req.on('error', (e) => {
  console.error('❌ Error:', e.message);
});

req.write(data);
req.end();
