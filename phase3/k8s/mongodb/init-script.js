db = db.getSiblingDB('admin');
db.createUser({
  user: 'admin',
  pwd: 'admin123',
  roles: [
    { role: 'userAdminAnyDatabase', db: 'admin' },
    { role: 'readWriteAnyDatabase', db: 'admin' }
  ]
});

db = db.getSiblingDB('demo_app');
db.createUser({
  user: 'demo_user',
  pwd: 'demo123',
  roles: [
    { role: 'readWrite', db: 'demo_app' }
  ]
});

// Create collections for the demo application
db.createCollection('articles');
db.createCollection('websites');
db.createCollection('users');

// Insert some sample data
db.articles.insertOne({
  title: "Welcome to Demo App",
  content: "This is a sample article",
  createdAt: new Date(),
  author: "system"
});

db.websites.insertOne({
  name: "Demo Website",
  url: "https://demo.example.com",
  description: "A sample website entry",
  createdAt: new Date()
});
