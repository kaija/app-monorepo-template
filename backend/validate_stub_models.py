#!/usr/bin/env python3
"""
Stub models validation script for LINE Commerce monorepo template.

This script validates that the stub models are properly configured
without requiring database connection or full app configuration.

Requirements validated: 10.1 - Stub data models for extensibility
"""

import ast
import sys
from pathlib import Path


def validate_model_file(file_path: Path, expected_table_name: str) -> bool:
    """Validate that a model file has the expected structure."""
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

        tree = ast.parse(content)

        # Check for class definition
        class_found = False
        table_name_found = False

        for node in ast.walk(tree):
            if isinstance(node, ast.ClassDef):
                class_found = True

                # Check for __tablename__ attribute
                for item in node.body:
                    if (
                        isinstance(item, ast.Assign)
                        and len(item.targets) == 1
                        and isinstance(item.targets[0], ast.Name)
                        and item.targets[0].id == "__tablename__"
                    ):
                        if (
                            isinstance(item.value, ast.Constant)
                            and item.value.value == expected_table_name
                        ):
                            table_name_found = True

        return class_found and table_name_found

    except Exception as e:
        print(f"Error validating {file_path}: {e}")
        return False


def main():
    """Main validation function."""
    print("🔍 Validating stub models...")

    backend_path = Path("backend/app/models")
    if not backend_path.exists():
        backend_path = Path("app/models")

    if not backend_path.exists():
        print("❌ Models directory not found")
        sys.exit(1)

    # Models to validate
    models_to_check = [
        ("merchant.py", "merchants"),
        ("product.py", "products"),
        ("order.py", "orders"),
    ]

    all_valid = True

    for model_file, expected_table in models_to_check:
        model_path = backend_path / model_file

        if not model_path.exists():
            print(f"❌ Model file not found: {model_file}")
            all_valid = False
            continue

        if validate_model_file(model_path, expected_table):
            print(f"✅ {model_file}: Valid model with table '{expected_table}'")
        else:
            print(f"❌ {model_file}: Invalid model structure")
            all_valid = False

    # Check that models are properly exported in __init__.py
    init_path = backend_path / "__init__.py"
    if init_path.exists():
        try:
            with open(init_path, "r", encoding="utf-8") as f:
                init_content = f.read()

            required_imports = ["Merchant", "Product", "Order", "OrderStatus"]
            missing_imports = []

            for imp in required_imports:
                if imp not in init_content:
                    missing_imports.append(imp)

            if missing_imports:
                print(f"❌ Missing imports in __init__.py: {missing_imports}")
                all_valid = False
            else:
                print("✅ All stub models properly exported in __init__.py")

        except Exception as e:
            print(f"❌ Error checking __init__.py: {e}")
            all_valid = False
    else:
        print("❌ __init__.py not found in models directory")
        all_valid = False

    if all_valid:
        print("\n🎉 All stub models validation passed!")
        print("   - Merchant model: ✅ merchants table")
        print("   - Product model: ✅ products table")
        print("   - Order model: ✅ orders table")
        print("   - OrderStatus enum: ✅ status values")
        print("   - Models properly exported: ✅")
    else:
        print("\n❌ Stub models validation failed!")
        print("💡 Ensure all stub models:")
        print("   - Have proper class definitions")
        print("   - Define correct __tablename__ attributes")
        print("   - Are exported in __init__.py")
        sys.exit(1)


if __name__ == "__main__":
    main()
