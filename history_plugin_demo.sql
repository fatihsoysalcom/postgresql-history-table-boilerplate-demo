-- Drop existing objects for a clean run
DROP TABLE IF EXISTS products_history;
DROP TABLE IF EXISTS products;
DROP FUNCTION IF EXISTS log_product_changes();

-- 1. Create a sample table
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Manually create a history table for it (boilerplate)
-- A custom plugin would typically generate this table automatically based on the main table's schema.
CREATE TABLE products_history (
    history_id SERIAL PRIMARY KEY,
    operation_type CHAR(1) NOT NULL, -- 'I' for Insert, 'U' for Update, 'D' for Delete
    product_id INT NOT NULL,
    old_name VARCHAR(100),
    new_name VARCHAR(100),
    old_price DECIMAL(10, 2),
    new_price DECIMAL(10, 2),
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT DEFAULT CURRENT_USER
);

-- 3. Manually create a trigger function (boilerplate)
-- A custom plugin would abstract this logic, allowing configuration of which columns to track
-- without writing this PL/pgSQL code for each table.
CREATE OR REPLACE FUNCTION log_product_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO products_history (
            operation_type, product_id,
            new_name, new_price,
            changed_by
        ) VALUES (
            'I', NEW.id,
            NEW.name, NEW.price,
            CURRENT_USER
        );
        RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
        -- Only log if relevant columns actually changed
        IF (OLD.name IS DISTINCT FROM NEW.name OR OLD.price IS DISTINCT FROM NEW.price) THEN
            INSERT INTO products_history (
                operation_type, product_id,
                old_name, new_name,
                old_price, new_price,
                changed_by
            ) VALUES (
                'U', NEW.id,
                OLD.name, NEW.name,
                OLD.price, NEW.price,
                CURRENT_USER
            );
        END IF;
        -- Update updated_at column automatically (common boilerplate)
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO products_history (
            operation_type, product_id,
            old_name, old_price,
            changed_by
        ) VALUES (
            'D', OLD.id,
            OLD.name, OLD.price,
            CURRENT_USER
        );
        RETURN OLD;
    END IF;
    RETURN NULL; -- Should not be reached
END;
$$ LANGUAGE plpgsql;

-- 4. Manually create triggers (boilerplate)
-- A custom plugin would typically provide a simple command like:
-- SELECT history.enable_history('products');
-- or ALTER TABLE products ADD COLUMN history_enabled BOOLEAN DEFAULT TRUE;
-- to automatically attach these triggers.
CREATE TRIGGER products_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON products
FOR EACH ROW EXECUTE FUNCTION log_product_changes();

-- Demonstrate the functionality

-- Insert a new product
INSERT INTO products (name, price) VALUES ('Laptop', 1200.00);
-- Expected: One 'I' entry in products_history

-- Update the product's price
UPDATE products SET price = 1150.00 WHERE name = 'Laptop';
-- Expected: One 'U' entry in products_history, showing old and new price

-- Update product name and price
UPDATE products SET name = 'Gaming Laptop', price = 1300.00 WHERE name = 'Laptop';
-- Expected: One 'U' entry in products_history, showing old and new name/price

-- Insert another product
INSERT INTO products (name, price) VALUES ('Mouse', 25.00);
-- Expected: One 'I' entry in products_history

-- Delete a product
DELETE FROM products WHERE name = 'Mouse';
-- Expected: One 'D' entry in products_history

-- View the main table
SELECT * FROM products;

-- View the history table
-- This table shows the audit trail, which the plugin aims to simplify creating and maintaining.
SELECT
    history_id,
    operation_type,
    product_id,
    old_name, new_name,
    old_price, new_price,
    changed_at,
    changed_by
FROM products_history
ORDER BY changed_at;
