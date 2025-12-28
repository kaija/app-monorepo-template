#!/bin/bash

# Validate Alembic migration files
# This script checks that migration files have proper structure

set -e

echo "🔍 Validating Alembic migration files..."
echo "======================================"

cd "$(dirname "$0")/../backend"

# Check if migration directory exists
if [ ! -d "alembic/versions" ]; then
    echo "❌ Migration directory not found: alembic/versions"
    exit 1
fi

# Count migration files
migration_count=$(find alembic/versions -name "*.py" ! -name "__init__.py" | wc -l)
echo "📁 Found $migration_count migration file(s)"

if [ $migration_count -eq 0 ]; then
    echo "⚠️  No migration files found"
    exit 0
fi

# Validate each migration file
python -c "
import os
import re

migration_dir = 'alembic/versions'
valid_count = 0
total_count = 0

for file in os.listdir(migration_dir):
    if file.endswith('.py') and file != '__init__.py':
        total_count += 1
        filepath = os.path.join(migration_dir, file)
        
        with open(filepath, 'r') as f:
            content = f.read()
            
        # Check for required Alembic functions
        has_upgrade = bool(re.search(r'def upgrade\(\).*:', content))
        has_downgrade = bool(re.search(r'def downgrade\(\).*:', content))
        
        if not has_upgrade:
            print(f'❌ Migration {file} missing upgrade() function')
            continue
            
        if not has_downgrade:
            print(f'❌ Migration {file} missing downgrade() function')
            continue
            
        # Check for revision identifiers
        has_revision = 'revision:' in content
        has_down_revision = 'down_revision:' in content
        
        if not has_revision:
            print(f'⚠️  Migration {file} missing revision identifier')
            
        if not has_down_revision:
            print(f'⚠️  Migration {file} missing down_revision identifier')
            
        print(f'✅ Migration {file} is valid')
        valid_count += 1

print(f'')
print(f'📊 Validation Summary:')
print(f'   Total files: {total_count}')
print(f'   Valid files: {valid_count}')
print(f'   Invalid files: {total_count - valid_count}')

if valid_count == total_count:
    print(f'✅ All migration files are valid!')
else:
    print(f'❌ {total_count - valid_count} migration file(s) have issues')
    exit(1)
"

echo ""
echo "✅ Migration validation completed successfully!"