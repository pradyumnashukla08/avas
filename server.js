// server.js - The complete and final backend for Avas

const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
// In a real app, you would use this for passwords: const bcrypt = require('bcrypt');

const app = express();
const port = 3000;

// Middleware
app.use(cors()); // Allows your frontend to make requests
app.use(express.json()); // Allows the server to understand JSON data from forms

// --- DATABASE CONNECTION ---
// Make sure these details match your PostgreSQL setup
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'avas_db', // The database name you created
  password: 'Pr@dyumna08', // Your PostgreSQL password
  port: 5000,
});

// --- API ROUTES (ENDPOINTS) ---

// GET: Fetch all plots with filtering
app.get('/api/plots', async (req, res) => {
  try {
    const { city, category, listing_type } = req.query;
    if (!city) return res.status(400).json({ error: 'City parameter is required' });

    let sqlQuery = 'SELECT *, plot_id as id FROM plots WHERE city = $1';
    let queryParams = [city];
    
    if (listing_type === 'Buy') sqlQuery += ` AND listing_type != 'For Rent'`;
    if (category === 'Land') sqlQuery += ` AND property_type IN ('NA Plot', 'Agricultural Land')`;
    
    sqlQuery += ' ORDER BY created_at DESC';

    const { rows } = await pool.query(sqlQuery, queryParams);
    res.json(rows);
  } catch (err) {
    console.error('Error fetching plots:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// GET: Fetch a single plot by its ID
app.get('/api/plots/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { rows } = await pool.query('SELECT *, plot_id as id FROM plots WHERE plot_id = $1', [id]);
        if (rows.length === 0) return res.status(404).json({ error: 'Plot not found' });
        res.json(rows[0]);
    } catch (err) {
        console.error('Error fetching single plot:', err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// POST: Handle user registration (Sign Up)
app.post('/api/register', async (req, res) => {
    try {
        const { name, email, password, mobile } = req.body;
        // IMPORTANT: In a real app, you MUST hash the password securely.
        // const salt = await bcrypt.genSalt(10);
        // const password_hash = await bcrypt.hash(password, salt);
        const password_hash = password; // FAKE HASH FOR DEMO - REPLACE WITH BCRYPT IN PRODUCTION

        const sql = `
            INSERT INTO users (full_name, email, password_hash, mobile_number)
            VALUES ($1, $2, $3, $4)
            RETURNING user_id, full_name, email;
        `;
        const { rows } = await pool.query(sql, [name, email, password_hash, mobile]);
        res.status(201).json(rows[0]);
    } catch (err) {
        console.error('Registration error:', err);
        res.status(500).json({ error: 'Could not register user. Email or mobile may already be in use.' });
    }
});

// POST: Handle new plot submissions
app.post('/api/plots', async (req, res) => {
    try {
        const { property_type, location, nearby_landmark, area_sqft, price, city } = req.body;
        // In a real app, owner_id would come from a secure authentication token (JWT)
        const owner_id = 1; // Hardcoded to the demo user for now

        const sql = `
            INSERT INTO plots (owner_id, property_type, location, nearby_landmark, area_sqft, price, city, listing_type)
            VALUES ($1, $2, $3, $4, $5, $6, $7, 'For Sale')
            RETURNING *, plot_id as id;
        `;
        const priceAsNumber = parseINR(price);
        const { rows } = await pool.query(sql, [owner_id, property_type, location, nearby_landmark, area_sqft, priceAsNumber, city]);
        res.status(201).json(rows[0]);
    } catch (err) {
        console.error('Add plot error:', err);
        res.status(500).json({ error: 'Server error while adding plot' });
    }
});

// POST: Handle submissions from the "Advertise" form
app.post('/api/advertise', async (req, res) => {
    try {
        const { ad_type, contact_name, contact_email, description } = req.body;
        const sql = `INSERT INTO ad_inquiries (ad_type, contact_name, contact_email, description) VALUES ($1, $2, $3, $4) RETURNING *`;
        const { rows } = await pool.query(sql, [ad_type, contact_name, contact_email, description]);
        res.status(201).json(rows[0]);
    } catch (err) {
        console.error('Error submitting inquiry:', err);
        res.status(500).json({ error: 'Failed to submit inquiry' });
    }
});


// Start the server
app.listen(port, () => {
  console.log(`✅ Avas backend server is running and ready at http://localhost:${port}`);
});

// Helper to convert string prices like "50 Lakhs" to a number
function parseINR(str) {
    if (!str || typeof str !== 'string') return 0;
    const s = str.replace(/[₹,]/g, '').toLowerCase();
    const croreMatch = s.match(/(\d+\.?\d*)\s*crore/);
    if (croreMatch) return parseFloat(croreMatch[1]) * 10000000;
    const lakhMatch = s.match(/(\d+\.?\d*)\s*lakh/);
    if (lakhMatch) return parseFloat(lakhMatch[1]) * 100000;
    return parseFloat(s) || 0;
}
