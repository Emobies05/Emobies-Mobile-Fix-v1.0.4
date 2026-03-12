const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const { WebSocketServer } = require('ws');
const multer = require('multer');

const app = express();
const port = process.env.PORT || 8080;
const upload = multer({ storage: multer.memoryStorage() });

app.use(cors());
app.use(express.json());

// ==================== IN-MEMORY DB ====================
let users = [];
let complaints = [];
let messages = [];
let notifications = [];

// ==================== HELPERS ====================
const genId = () => crypto.randomBytes(8).toString('hex');
const genToken = () => crypto.randomBytes(16).toString('hex');

// ==================== SMS (Twilio) ====================
const sendSMS = async (phone, message) => {
  const accountSid = process.env.TWILIO_SID;
  const authToken = process.env.TWILIO_TOKEN;
  const from = process.env.TWILIO_PHONE;
  if (!accountSid) return;
  try {
    await fetch(`https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`, {
      method: 'POST',
      headers: {
        'Authorization': 'Basic ' + Buffer.from(`${accountSid}:${authToken}`).toString('base64'),
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: `To=%2B${phone}&From=${from}&Body=${encodeURIComponent(message)}`
    });
    console.log('SMS sent to', phone);
  } catch(e) {
    console.log('SMS failed:', e.message);
  }
};

// ==================== HEALTH ====================
app.get('/health', (req, res) => res.json({ status: 'OK', time: new Date() }));

// ==================== AUTH MIDDLEWARE ====================
const auth = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  const user = users.find(u => u.token === token);
  if (!user) return res.status(401).json({ error: 'Unauthorized' });
  req.user = user;
  next();
};

// ==================== AUTH ====================

// Register
app.post('/api/register', (req, res) => {
  const { name, phone, password, role } = req.body;
  if (!name || !phone || !password) return res.status(400).json({ error: 'Missing fields' });
  if (users.find(u => u.phone === phone)) return res.status(400).json({ error: 'Phone already registered' });
  const user = {
    id: genId(), name, phone, password,
    role: role || 'customer', token: null,
    emoCoins: 0, createdAt: new Date()
  };
  users.push(user);
  res.json({ success: true, message: 'Registered successfully' });
});

// Login
app.post('/api/login', (req, res) => {
  const { phone, password } = req.body;
  const user = users.find(u => u.phone === phone && u.password === password);
  if (!user) return res.status(401).json({ error: 'Invalid credentials' });
  user.token = genToken();
  res.json({ success: true, token: user.token, role: user.role, name: user.name, id: user.id });
});

// Profile
app.get('/api/user/profile', auth, (req, res) => {
  const { password, token, ...safe } = req.user;
  res.json(safe);
});

// ==================== COMPLAINTS ====================

// Register complaint
app.post('/api/complaints', auth, (req, res) => {
  const { deviceName, imei, natureOfComplaint, bodyCondition, pickupAddress, location } = req.body;
  if (!deviceName || !pickupAddress) return res.status(400).json({ error: 'Missing fields' });
  const complaint = {
    id: genId(),
    customerId: req.user.id,
    customerName: req.user.name,
    customerPhone: req.user.phone,
    deviceName, imei, natureOfComplaint, bodyCondition, pickupAddress, location,
    status: 'Registered',
    deliveryBoyId: null,
    serviceCentreId: null,
    timeline: [{ status: 'Complaint Registered', time: new Date() }],
    images: { pickup: [], dropoff: [], received: [], returned: [] },
    amount: null,
    paymentMethod: null,
    paymentDone: false,
    createdAt: new Date()
  };
  complaints.push(complaint);

  // Notify supervisors
  users.filter(u => u.role === 'supervisor').forEach(sup => {
    notifications.push({ id: genId(), userId: sup.id, message: `New complaint from ${req.user.name}`, complaintId: complaint.id, read: false, time: new Date() });
  });

  // SMS to customer
  sendSMS(req.user.phone, `Emobies: Your complaint for ${deviceName} has been registered. ID: ${complaint.id}`);

  res.json({ success: true, complaint });
});

// Get my complaints (customer)
app.get('/api/complaints/my', auth, (req, res) => {
  const myComplaints = complaints.filter(c => c.customerId === req.user.id);
  res.json(myComplaints);
});

// Get all complaints (supervisor/admin)
app.get('/api/complaints', auth, (req, res) => {
  if (!['supervisor', 'superadmin'].includes(req.user.role)) return res.status(403).json({ error: 'Forbidden' });
  res.json(complaints);
});

// Get complaints by status
app.get('/api/complaints/status/:status', auth, (req, res) => {
  const filtered = complaints.filter(c => c.status === req.params.status);
  res.json(filtered);
});

// Assign delivery boy + service centre
app.post('/api/complaints/:id/assign', auth, (req, res) => {
  if (!['supervisor', 'superadmin'].includes(req.user.role)) return res.status(403).json({ error: 'Forbidden' });
  const complaint = complaints.find(c => c.id === req.params.id);
  if (!complaint) return res.status(404).json({ error: 'Not found' });
  const { deliveryBoyId, serviceCentreId } = req.body;
  complaint.deliveryBoyId = deliveryBoyId;
  complaint.serviceCentreId = serviceCentreId;
  complaint.status = 'Assigned';
  complaint.timeline.push({ status: 'Agent Assigned for Pickup', time: new Date() });

  notifications.push({ id: genId(), userId: deliveryBoyId, message: `New pickup assigned`, complaintId: complaint.id, read: false, time: new Date() });
  notifications.push({ id: genId(), userId: complaint.customerId, message: `Agent assigned for your complaint`, complaintId: complaint.id, read: false, time: new Date() });

  // SMS to customer
  sendSMS(complaint.customerPhone, `Emobies: An agent has been assigned to pick up your ${complaint.deviceName}.`);

  res.json({ success: true, complaint });
});

// Update complaint status
app.post('/api/complaints/:id/status', auth, (req, res) => {
  const complaint = complaints.find(c => c.id === req.params.id);
  if (!complaint) return res.status(404).json({ error: 'Not found' });
  const { status, images } = req.body;
  complaint.status = status;
  complaint.timeline.push({ status, time: new Date() });
  if (images) Object.assign(complaint.images, images);

  notifications.push({ id: genId(), userId: complaint.customerId, message: `Your complaint status: ${status}`, complaintId: complaint.id, read: false, time: new Date() });

  // SMS to customer
  sendSMS(complaint.customerPhone, `Emobies: Your ${complaint.deviceName} status updated: ${status}`);

  res.json({ success: true, complaint });
});

// Set repair amount
app.post('/api/complaints/:id/amount', auth, (req, res) => {
  const complaint = complaints.find(c => c.id === req.params.id);
  if (!complaint) return res.status(404).json({ error: 'Not found' });
  const { amount, quality } = req.body;
  complaint.amount = amount;
  complaint.quality = quality;
  complaint.timeline.push({ status: `Quote sent: AED ${amount}`, time: new Date() });
  notifications.push({ id: genId(), userId: complaint.customerId, message: `Repair quote: AED ${amount}`, complaintId: complaint.id, read: false, time: new Date() });

  // SMS to customer
  sendSMS(complaint.customerPhone, `Emobies: Repair quote for your ${complaint.deviceName}: AED ${amount}. Please approve in the app.`);

  res.json({ success: true });
});

// Accept/reject amount
app.post('/api/complaints/:id/accept', auth, (req, res) => {
  const complaint = complaints.find(c => c.id === req.params.id);
  if (!complaint) return res.status(404).json({ error: 'Not found' });
  const { accepted } = req.body;
  if (accepted) {
    complaint.status = 'Repair Started';
    complaint.timeline.push({ status: 'Customer Accepted Quote - Repair Started', time: new Date() });
  } else {
    complaint.status = 'Quote Rejected';
    complaint.timeline.push({ status: 'Customer Rejected Quote', time: new Date() });
  }
  res.json({ success: true });
});

// Payment
app.post('/api/complaints/:id/payment', auth, (req, res) => {
  const complaint = complaints.find(c => c.id === req.params.id);
  if (!complaint) return res.status(404).json({ error: 'Not found' });
  const { method } = req.body;
  complaint.paymentMethod = method;
  complaint.paymentDone = true;
  complaint.status = 'Payment Done';
  complaint.timeline.push({ status: `Payment received - ${method}`, time: new Date() });

  // EmoCoins for customer
  const customer = users.find(u => u.id === complaint.customerId);
  if (customer) customer.emoCoins += 10;

  // SMS to customer
  sendSMS(complaint.customerPhone, `Emobies: Payment received! +10 EmoCoins added. Thank you!`);

  res.json({ success: true });
});

// ==================== IMAGE UPLOAD (Cloudinary) ====================
app.post('/api/upload', auth, upload.single('image'), async (req, res) => {
  try {
    const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
    if (!cloudName) return res.status(500).json({ error: 'Cloudinary not configured' });

    const formData = new FormData();
    const blob = new Blob([req.file.buffer], { type: req.file.mimetype });
    formData.append('file', blob);
    formData.append('upload_preset', 'emobies');

    const response = await fetch(
      `https://api.cloudinary.com/v1_1/${cloudName}/image/upload`,
      { method: 'POST', body: formData }
    );
    const data = await response.json();
    res.json({ success: true, url: data.secure_url });
  } catch(e) {
    res.status(500).json({ error: 'Upload failed' });
  }
});

// ==================== DELIVERY BOY ====================
app.get('/api/delivery/complaints', auth, (req, res) => {
  if (req.user.role !== 'delivery') return res.status(403).json({ error: 'Forbidden' });
  const myJobs = complaints.filter(c => c.deliveryBoyId === req.user.id);
  res.json(myJobs);
});

// ==================== SERVICE CENTRE ====================
app.get('/api/service/complaints', auth, (req, res) => {
  if (req.user.role !== 'service') return res.status(403).json({ error: 'Forbidden' });
  const myJobs = complaints.filter(c => c.serviceCentreId === req.user.id);
  res.json(myJobs);
});

// ==================== CHAT ====================
app.post('/api/chat', auth, (req, res) => {
  const { complaintId, to, message } = req.body;
  const msg = { id: genId(), complaintId, from: req.user.id, fromName: req.user.name, fromRole: req.user.role, to, message, time: new Date() };
  messages.push(msg);
  notifications.push({ id: genId(), userId: to, message: `New message from ${req.user.name}`, complaintId, read: false, time: new Date() });
  res.json({ success: true, msg });
});

app.get('/api/chat/:complaintId', auth, (req, res) => {
  const msgs = messages.filter(m => m.complaintId === req.params.complaintId);
  res.json(msgs);
});

// ==================== NOTIFICATIONS ====================
app.get('/api/notifications', auth, (req, res) => {
  const myNotifs = notifications.filter(n => n.userId === req.user.id);
  res.json(myNotifs);
});

app.post('/api/notifications/read', auth, (req, res) => {
  notifications.filter(n => n.userId === req.user.id).forEach(n => n.read = true);
  res.json({ success: true });
});

// ==================== SUPER ADMIN ====================
app.post('/api/admin/create', auth, (req, res) => {
  if (req.user.role !== 'superadmin') return res.status(403).json({ error: 'Forbidden' });
  const { name, phone, email, role, location } = req.body;
  if (users.find(u => u.phone === phone)) return res.status(400).json({ error: 'Already exists' });
  const tempPassword = genId().slice(0, 8);
  const user = { id: genId(), name, phone, email, password: tempPassword, role, location, token: null, emoCoins: 0, createdAt: new Date() };
  users.push(user);
  res.json({ success: true, tempPassword, user: { id: user.id, name, phone, email, role } });
});

app.get('/api/admin/staff', auth, (req, res) => {
  if (!['supervisor', 'superadmin'].includes(req.user.role)) return res.status(403).json({ error: 'Forbidden' });
  const staff = users.filter(u => u.role !== 'customer').map(({ password, token, ...s }) => s);
  res.json(staff);
});

app.get('/api/admin/delivery', auth, (req, res) => {
  if (!['supervisor', 'superadmin'].includes(req.user.role)) return res.status(403).json({ error: 'Forbidden' });
  const delivery = users.filter(u => u.role === 'delivery').map(({ password, token, ...s }) => s);
  res.json(delivery);
});

app.get('/api/admin/service', auth, (req, res) => {
  if (!['supervisor', 'superadmin'].includes(req.user.role)) return res.status(403).json({ error: 'Forbidden' });
  const service = users.filter(u => u.role === 'service').map(({ password, token, ...s }) => s);
  res.json(service);
});

// ==================== EMOCOIN ====================
app.get('/api/emocoin/balance', auth, (req, res) => {
  res.json({ balance: req.user.emoCoins || 0 });
});

app.post('/api/emocoin/daily', auth, (req, res) => {
  req.user.emoCoins = (req.user.emoCoins || 0) + 2;
  res.json({ success: true, balance: req.user.emoCoins });
});

// ==================== EMOWALL AI ====================
app.post('/api/ai/chat', auth, async (req, res) => {
  const { message } = req.body;
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) return res.json({ reply: 'AI not configured' });
  try {
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${apiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: `You are Emowall AI assistant for Emobies mobile repair service. Help with repair queries and crypto/TheWall wallet questions. User: ${message}` }] }]
      })
    });
    const data = await response.json();
    const reply = data.candidates?.[0]?.content?.parts?.[0]?.text || 'Sorry, try again';
    res.json({ reply });
  } catch(e) {
    res.json({ reply: 'AI error, try again' });
  }
});

// ==================== SEED SUPERADMIN ====================
users.push({
  id: genId(),
  name: 'Divin K.K.',
  phone: process.env.ADMIN_PHONE || '9847842172',
  password: process.env.ADMIN_PASSWORD || 'Emobies@2026!',
  role: 'superadmin',
  token: null,
  emoCoins: 0,
  createdAt: new Date()
});

// ==================== START SERVER ====================
const server = app.listen(port, () => console.log(`Emobies live on port ${port}`));

// ==================== WEBSOCKET (Real-time Chat) ====================
const wss = new WebSocketServer({ server });
const clients = new Map();

wss.on('connection', (ws, req) => {
  const userId = req.url.split('?userId=')[1];
  if (userId) clients.set(userId, ws);
  console.log('WS connected:', userId);

  ws.on('message', (data) => {
    try {
      const { to, message, complaintId, fromName } = JSON.parse(data);
      const msg = { id: genId(), complaintId, from: userId, fromName, to, message, time: new Date() };
      messages.push(msg);

      // Send to recipient if online
      const toClient = clients.get(to);
      if (toClient && toClient.readyState === 1) {
        toClient.send(JSON.stringify(msg));
      }
    } catch(e) {
      console.log('WS message error:', e.message);
    }
  });

  ws.on('close', () => {
    clients.delete(userId);
    console.log('WS disconnected:', userId);
  });
});
