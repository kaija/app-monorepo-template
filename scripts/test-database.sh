#!/bin/bash

# Database Testing Script
# Tests migrations, schema validation, and basic operations

set -e

echo "🗄️  Testing Database Operations..."
echo "================================="

cd "$(dirname "$0")/../backend"

# Check if we have a database URL
if [ -z "$DATABASE_URL" ]; then
    echo "⚠️  DATABASE_URL not set. Using default test database."
    export DATABASE_URL="postgresql://testuser:testpassword@localhost:5432/testdb"
fi

# Check if we have JWT_SECRET_KEY
if [ -z "$JWT_SECRET_KEY" ]; then
    echo "⚠️  JWT_SECRET_KEY not set. Using test key."
    export JWT_SECRET_KEY="test-jwt-secret-key-for-local-testing-only-not-for-production-use"
fi

echo "📊 Database URL: $DATABASE_URL"

# Install dependencies if needed
if ! python -c "import alembic" 2>/dev/null; then
    echo "📦 Installing dependencies..."
    pip install -r requirements.txt -e .
fi

echo ""
echo "🔍 Step 1: Validating migration files..."
../scripts/validate-migrations.sh

echo ""
echo "🔄 Step 2: Testing fresh migration..."
alembic upgrade head
echo "✅ Fresh migration successful"

echo ""
echo "🔙 Step 3: Testing migration rollback..."
alembic downgrade -1
echo "✅ Migration rollback successful"

echo ""
echo "🔄 Step 4: Testing migration re-apply..."
alembic upgrade head
echo "✅ Migration re-apply successful"

echo ""
echo "🔍 Step 5: Validating database schema..."
python -c "
from sqlalchemy import create_engine, inspect
import os

engine = create_engine(os.getenv('DATABASE_URL'))
inspector = inspect(engine)

# Check that expected tables exist
tables = inspector.get_table_names()
expected_tables = ['users', 'items', 'alembic_version']

print('📋 Found tables:', ', '.join(tables))

for table in expected_tables:
    if table not in tables:
        raise ValueError(f'Expected table {table} not found')
    print(f'✅ Table {table} exists')

# Check users table structure
users_columns = [col['name'] for col in inspector.get_columns('users')]
expected_users_columns = ['id', 'email', 'password_hash', 'oauth_provider', 'oauth_id', 'display_name', 'avatar_url', 'is_active', 'created_at', 'updated_at']

print(f'📋 Users table columns: {len(users_columns)} found')
for col in expected_users_columns:
    if col not in users_columns:
        raise ValueError(f'Expected column {col} not found in users table')

# Check items table structure  
items_columns = [col['name'] for col in inspector.get_columns('items')]
expected_items_columns = ['id', 'name', 'description', 'price', 'user_id', 'created_at', 'updated_at']

print(f'📋 Items table columns: {len(items_columns)} found')
for col in expected_items_columns:
    if col not in items_columns:
        raise ValueError(f'Expected column {col} not found in items table')

print('✅ Database schema validation successful')
"

echo ""
echo "📝 Step 6: Testing basic CRUD operations..."
python -c "
from sqlalchemy import create_engine, text
import os

engine = create_engine(os.getenv('DATABASE_URL'))

with engine.connect() as conn:
    # Insert test user
    result = conn.execute(text('''
        INSERT INTO users (id, email, display_name, is_active) 
        VALUES (uuid_generate_v4(), 'test@example.com', 'Test User', true)
        RETURNING id
    '''))
    user_id = result.scalar()
    print(f'✅ Created test user with ID: {user_id}')
    
    # Insert test item
    result = conn.execute(text('''
        INSERT INTO items (id, name, description, price, user_id) 
        VALUES (uuid_generate_v4(), 'Test Item', 'Test Description', 99.99, :user_id)
        RETURNING id
    '''), {'user_id': user_id})
    item_id = result.scalar()
    print(f'✅ Created test item with ID: {item_id}')
    
    # Query data
    result = conn.execute(text('SELECT COUNT(*) FROM users'))
    user_count = result.scalar()
    print(f'✅ Found {user_count} user(s) in database')
    
    result = conn.execute(text('SELECT COUNT(*) FROM items'))
    item_count = result.scalar()
    print(f'✅ Found {item_count} item(s) in database')
    
    # Clean up test data
    conn.execute(text('DELETE FROM items WHERE user_id = :user_id'), {'user_id': user_id})
    conn.execute(text('DELETE FROM users WHERE id = :user_id'), {'user_id': user_id})
    conn.commit()
    print('✅ Test data cleaned up')

print('✅ Basic CRUD operations successful')
"

echo ""
echo "🎉 All database tests passed!"
echo "✅ Migration files are valid"
echo "✅ Migrations work correctly"
echo "✅ Schema is properly structured"
echo "✅ Basic operations work"