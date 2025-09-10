-- ========= AVAS DATABASE RESET SCRIPT (v2) =========
-- This script will now DELETE existing tables before creating them.
-- You can run this safely multiple times.

-- Drop tables in reverse order of creation to respect dependencies.
DROP TABLE IF EXISTS ad_inquiries;
DROP TABLE IF EXISTS plots;
DROP TABLE IF EXISTS users;
DROP TYPE IF EXISTS subscription_tier; -- The custom type must be dropped after the tables that use it.

-- ========= SECTION 1: TYPES & TABLES =========

-- Create a custom type for subscription plans.
CREATE TYPE subscription_tier AS ENUM ('free', 'enterprise', 'pro');

-- Create the users table.
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL, -- IMPORTANT: Store a HASH, not the plain password.
    mobile_number VARCHAR(20) UNIQUE,
    subscription_plan subscription_tier DEFAULT 'free',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create the plots table, which depends on the users table.
CREATE TABLE plots (
    plot_id SERIAL PRIMARY KEY,
    owner_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    property_type VARCHAR(100),
    location TEXT NOT NULL,
    nearby_landmark TEXT,
    area_sqft INT NOT NULL,
    price BIGINT NOT NULL,
    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),
    image_urls TEXT[],
    is_verified BOOLEAN DEFAULT false,
    city TEXT NOT NULL,
    facing VARCHAR(50),
    vastu_score INT,
    amenities TEXT[],
    status VARCHAR(50) DEFAULT 'Available',
    listing_type VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create the advertisement inquiries table.
CREATE TABLE ad_inquiries (
    inquiry_id SERIAL PRIMARY KEY,
    ad_type VARCHAR(50) NOT NULL,
    contact_name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255) NOT NULL,
    description TEXT,
    inquiry_date TIMESTAMPTZ DEFAULT NOW()
);


-- ========= SECTION 2: INITIAL DATA INSERTION =========

-- Insert a sample user (user_id will be 1).
INSERT INTO users (full_name, email, password_hash, mobile_number) 
VALUES ('Demo User', 'user@example.com', 'this_should_be_a_real_hash', '9999988888');

-- Insert the initial plot data, linking it to the user with owner_id = 1.
INSERT INTO plots 
(owner_id, location, city, area_sqft, price, facing, vastu_score, image_urls, status, property_type, amenities, latitude, longitude, created_at, is_verified, listing_type) 
VALUES
(1, 'Hinjawadi Phase 1', 'Pune', 2000, 9000000, 'East', 85, '{"https://images.pexels.com/photos/221540/pexels-photo-221540.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1"}', 'Available', 'Residential Plot', '{"Gated Community", "24/7 Security"}', 18.5913000, 73.7423000, '2025-09-08T16:56:56.136Z', true, 'For Sale'),
(1, 'Wakad', 'Pune', 1500, 7500000, 'North-East', 92, '{"https://images.pexels.com/photos/186077/pexels-photo-186077.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1"}', 'Available', 'Residential Plot', '{"Park", "Clubhouse"}', 18.6083000, 73.7634000, '2025-09-06T16:56:56.136Z', false, 'For Sale'),
(1, 'Kharadi', 'Pune', 3000, 15000000, 'West', 68, '{"https://images.pexels.com/photos/209315/pexels-photo-209315.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1"}', 'Available', 'NA Plot', '{"Water Connection"}', 18.5517000, 73.9362000, '2025-08-30T16:56:56.136Z', true, 'For Sale'),
(1, 'Andheri West', 'Mumbai', 1200, 50000000, 'East', 88, '{"https://images.pexels.com/photos/210617/pexels-photo-210617.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1"}', 'Available', 'Residential Plot', '{"Gated Community"}', 19.1365000, 72.8275000, '2025-09-04T16:56:56.136Z', false, 'For Sale'),
(1, 'Panvel', 'Mumbai', 5000, 25000000, 'North', 95, '{"https://images.pexels.com/photos/280222/pexels-photo-280222.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1"}', 'Available', 'NA Plot', '{"Road Touch"}', 18.9894000, 73.1175000, '2025-09-01T16:56:56.136Z', true, 'For Sale'),
(1, 'DLF Phase 5', 'Delhi NCR', 4500, 150000000, 'North-East', 94, '{"https://images.pexels.com/photos/313960/pexels-photo-313960.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1"}', 'Available', 'Residential Plot', '{"24/7 Security"}', 28.4595000, 77.0266000, '2025-09-07T16:56:56.136Z', true, 'For Sale');

-- Log a success message.
SELECT 'SUCCESS: Database schema reset and initial data inserted.' as status;