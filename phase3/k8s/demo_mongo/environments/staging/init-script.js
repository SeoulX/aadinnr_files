// MongoDB initialization script for staging environment
db = db.getSiblingDB('admin');

// Create admin user for staging
db.createUser({
  user: 'admin',
  pwd: 'admin123',
  roles: [
    { role: 'userAdminAnyDatabase', db: 'admin' },
    { role: 'readWriteAnyDatabase', db: 'admin' }
  ]
});

// Switch to application database
db = db.getSiblingDB('demo_app');

// Create application user for staging
db.createUser({
  user: 'appuser',
  pwd: 'apppassword',
  roles: [
    { role: 'readWrite', db: 'demo_app' }
  ]
});

// Create initial collections
db.createCollection('users');
db.createCollection('products');
db.createCollection('orders');

// Insert sample data for staging
db.users.insertMany([
  {
    name: 'John Doe',
    email: 'john@example.com',
    role: 'admin',
    createdAt: new Date()
  },
  {
    name: 'Jane Smith',
    email: 'jane@example.com',
    role: 'user',
    createdAt: new Date()
  }
]);

db.products.insertMany([
  {
    name: 'Sample Product 1',
    price: 99.99,
    category: 'electronics',
    stock: 100,
    createdAt: new Date()
  },
  {
    name: 'Sample Product 2',
    price: 49.99,
    category: 'clothing',
    stock: 50,
    createdAt: new Date()
  }
]);

db.orders.insertOne({
  userId: 'user1',
  products: ['product1', 'product2'],
  total: 149.98,
  status: 'pending',
  createdAt: new Date()
});

print('MongoDB staging environment initialization completed successfully!');
print('Created collections: users, products, orders');
print('Created users: admin, appuser');
print('Sample data inserted for testing');
