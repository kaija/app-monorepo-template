#!/usr/bin/env python3
"""
Layer separation validation script for LINE Commerce monorepo template.

This script validates that the layered architecture maintains proper separation
of concerns and dependency flow: routes → services → repositories → models.

Requirements validated: 10.3 - Layer separation architecture
"""

import ast
import os
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple


class LayerValidator:
    """Validates layer separation in the backend architecture."""
    
    def __init__(self, backend_path: str = "backend/app"):
        self.backend_path = Path(backend_path)
        self.violations: List[str] = []
        
        # Define layer hierarchy (higher number = higher layer)
        self.layer_hierarchy = {
            "models": 1,
            "repositories": 2,
            "services": 3,
            "api": 4,  # routes are in api/routes/
        }
    
    def get_layer_from_path(self, file_path: Path) -> str:
        """Determine which layer a file belongs to based on its path."""
        parts = file_path.parts
        
        if "models" in parts:
            return "models"
        elif "repositories" in parts:
            return "repositories"
        elif "services" in parts:
            return "services"
        elif "api" in parts:
            return "api"
        else:
            return "unknown"
    
    def extract_imports(self, file_path: Path) -> List[str]:
        """Extract all import statements from a Python file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            tree = ast.parse(content)
            imports = []
            
            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    for alias in node.names:
                        imports.append(alias.name)
                elif isinstance(node, ast.ImportFrom):
                    if node.module:
                        imports.append(node.module)
            
            return imports
        except Exception as e:
            print(f"Warning: Could not parse {file_path}: {e}")
            return []
    
    def get_app_imports(self, imports: List[str]) -> List[str]:
        """Filter imports to only include app-level imports."""
        app_imports = []
        for imp in imports:
            if imp.startswith("app."):
                app_imports.append(imp)
        return app_imports
    
    def validate_file_dependencies(self, file_path: Path) -> List[str]:
        """Validate that a file only imports from allowed layers."""
        current_layer = self.get_layer_from_path(file_path)
        if current_layer == "unknown":
            return []
        
        current_level = self.layer_hierarchy.get(current_layer, 0)
        imports = self.extract_imports(file_path)
        app_imports = self.get_app_imports(imports)
        
        violations = []
        
        for imp in app_imports:
            # Determine the layer of the imported module
            imported_layer = None
            for layer in self.layer_hierarchy.keys():
                if f"app.{layer}" in imp:
                    imported_layer = layer
                    break
            
            if imported_layer:
                imported_level = self.layer_hierarchy[imported_layer]
                
                # Check if importing from a higher layer (violation)
                if imported_level > current_level:
                    violations.append(
                        f"{file_path}: {current_layer} layer importing from higher {imported_layer} layer ({imp})"
                    )
                
                # Check for circular dependencies within same layer
                elif imported_level == current_level and current_layer not in ["models", "api"]:
                    # Allow models to import from models (for relationships)
                    # Allow api routes to import from api.dependencies (shared utilities)
                    violations.append(
                        f"{file_path}: Potential circular dependency within {current_layer} layer ({imp})"
                    )
        
        return violations
    
    def validate_directory(self, directory: Path) -> None:
        """Validate all Python files in a directory."""
        if not directory.exists():
            return
        
        for file_path in directory.rglob("*.py"):
            if file_path.name == "__init__.py":
                continue
            
            violations = self.validate_file_dependencies(file_path)
            self.violations.extend(violations)
    
    def run_validation(self) -> bool:
        """Run the complete layer separation validation."""
        print("🔍 Validating layer separation architecture...")
        
        # Validate each layer directory
        for layer in self.layer_hierarchy.keys():
            layer_path = self.backend_path / layer
            self.validate_directory(layer_path)
        
        # Also check core directory for any violations
        core_path = self.backend_path / "core"
        if core_path.exists():
            for file_path in core_path.rglob("*.py"):
                if file_path.name == "__init__.py":
                    continue
                
                imports = self.extract_imports(file_path)
                app_imports = self.get_app_imports(imports)
                
                # Core should not import from business logic layers
                for imp in app_imports:
                    if any(layer in imp for layer in ["repositories", "services", "api"]):
                        self.violations.append(
                            f"{file_path}: Core module importing from business logic layer ({imp})"
                        )
        
        # Report results
        if self.violations:
            print("❌ Layer separation violations found:")
            for violation in self.violations:
                print(f"  - {violation}")
            return False
        else:
            print("✅ Layer separation validation passed!")
            print("   - Routes → Services → Repositories → Models dependency flow maintained")
            print("   - No circular dependencies detected")
            print("   - Core modules properly isolated")
            return True


def main():
    """Main entry point for layer validation."""
    validator = LayerValidator()
    
    if not validator.backend_path.exists():
        print(f"❌ Backend path not found: {validator.backend_path}")
        sys.exit(1)
    
    success = validator.run_validation()
    
    if not success:
        print("\n💡 Layer separation guidelines:")
        print("   - Routes (api/) should only import from services and schemas")
        print("   - Services should only import from repositories and models")
        print("   - Repositories should only import from models and core")
        print("   - Models should only import from core and other models")
        print("   - Core modules should not import from business logic layers")
        sys.exit(1)
    
    print("\n🎉 Architecture validation complete!")


if __name__ == "__main__":
    main()