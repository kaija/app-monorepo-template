"""Tests for stub models to ensure they are properly configured."""

import pytest
from decimal import Decimal
from uuid import uuid4


def test_model_imports():
    """Test that all stub models can be imported from the models package."""
    # Import models directly to avoid config issues
    from app.models.merchant import Merchant
    from app.models.product import Product
    from app.models.order import Order, OrderStatus
    
    # Verify classes are properly imported
    assert Merchant.__name__ == "Merchant"
    assert Product.__name__ == "Product"
    assert Order.__name__ == "Order"
    assert OrderStatus.__name__ == "OrderStatus"
    
    # Verify they have the expected table names
    assert Merchant.__tablename__ == "merchants"
    assert Product.__tablename__ == "products"
    assert Order.__tablename__ == "orders"


def test_order_status_enum():
    """Test that OrderStatus enum has all expected values."""
    from app.models.order import OrderStatus
    
    expected_statuses = {
        "pending", "confirmed", "processing", 
        "shipped", "delivered", "cancelled", "refunded"
    }
    
    actual_statuses = {status.value for status in OrderStatus}
    assert actual_statuses == expected_statuses


def test_merchant_model_structure():
    """Test that Merchant model has expected attributes."""
    from app.models.merchant import Merchant
    
    # Check that the model has the expected columns
    columns = [col.name for col in Merchant.__table__.columns]
    expected_columns = [
        'id', 'name', 'description', 'contact_email', 
        'website_url', 'is_active', 'created_at', 'updated_at'
    ]
    
    for col in expected_columns:
        assert col in columns, f"Missing column: {col}"


def test_product_model_structure():
    """Test that Product model has expected attributes."""
    from app.models.product import Product
    
    # Check that the model has the expected columns
    columns = [col.name for col in Product.__table__.columns]
    expected_columns = [
        'id', 'name', 'description', 'price', 'sku', 
        'stock_quantity', 'merchant_id', 'is_active', 
        'created_at', 'updated_at'
    ]
    
    for col in expected_columns:
        assert col in columns, f"Missing column: {col}"


def test_order_model_structure():
    """Test that Order model has expected attributes."""
    from app.models.order import Order
    
    # Check that the model has the expected columns
    columns = [col.name for col in Order.__table__.columns]
    expected_columns = [
        'id', 'order_number', 'user_id', 'status', 
        'total_amount', 'currency', 'notes', 
        'created_at', 'updated_at'
    ]
    
    for col in expected_columns:
        assert col in columns, f"Missing column: {col}"