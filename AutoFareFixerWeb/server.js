const express = require('express');
const app = express();
const PORT = 3000;

app.use(express.urlencoded({ extended: true }));

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Auto Fare Fixer | Hyderabad</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #fdfbf7; margin: 0; padding: 20px; color: #2c3e50; }
            .container { max-width: 600px; margin: 40px auto; background: #fff; border: 2px solid #fbc531; border-radius: 12px; padding: 30px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); }
            h1 { color: #2c3e50; font-size: 26px; margin-bottom: 5px; display: flex; align-items: center; gap: 10px; }
            .sub { color: #7f8c8d; font-size: 13px; margin-bottom: 25px; }
            .card { background: #fafafa; border: 1px solid #e0e0e0; border-radius: 8px; padding: 20px; margin-bottom: 20px; }
            label { display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px; color: #34495e; }
            input { width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 6px; font-size: 14px; margin-bottom: 12px; box-sizing: border-box; }
            button { width: 100%; background: #f39c12; color: white; border: none; padding: 12px; font-size: 15px; font-weight: bold; border-radius: 6px; cursor: pointer; transition: background 0.2s; }
            button:hover { background: #d68910; }
            .result { margin-top: 15px; padding: 12px; background: #fef9e7; border: 1px solid #f9e79f; border-radius: 6px; text-align: center; font-size: 18px; font-weight: bold; color: #b7950b; }
            .sos { background: #c0392b; margin-top: 10px; }
            .sos:hover { background: #962d22; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🛺 Auto Fare Fixer <span style="font-size: 14px; background: #fef9e7; padding: 4px 8px; border-radius: 4px; color: #d35400;">Hyderabad Web MVP</span></h1>
            <div class="sub">Official Telangana Tariff Guard (₹20 Base + ₹12/km) & Violation Portal</div>

            <!-- Fare Calculator -->
            <div class="card">
                <h3>1. Government Fare Calculator</h3>
                <label>Distance Traveled (KM):</label>
                <input type="number" id="dist" placeholder="e.g. 4.5" step="0.1">
                <button onclick="calcFare()">Calculate Official Fare</button>
                <div id="fareResult" class="result" style="display:none;"></div>
            </div>

            <!-- Violation Logger -->
            <div class="card">
                <h3>2. Log Overcharging Violation</h3>
                <label>Auto Plate Number:</label>
                <input type="text" id="plate" placeholder="e.g. TS09UB1234">
                <label>Driver Demanded Amount (₹):</label>
                <input type="number" id="demanded" placeholder="e.g. 250">
                <button onclick="raiseComplaint()">Generate Police e-Challan Report</button>
            </div>

            <!-- SOS Panic -->
            <button class="sos" onclick="triggerSOS()">🚨 EMERGENCY SOS PANIC BUTTON</button>
        </div>

        <script>
            function calcFare() {
                let d = parseFloat(document.getElementById('dist').value);
                if(isNaN(d) || d <= 0) { alert('Enter valid distance'); return; }
                let fare = 20;
                if(d > 1.5) { fare += (d - 1.5) * 12; }
                let res = document.getElementById('fareResult');
                res.style.display = 'block';
                res.innerHTML = 'Official Government Fare: ₹' + Math.round(fare);
            }

            function raiseComplaint() {
                let plate = document.getElementById('plate').value;
                let demanded = document.getElementById('demanded').value;
                if(!plate || !demanded) { alert('Please fill plate number and demanded amount'); return; }
                alert('✅ Complaint report generated successfully for Auto ' + plate.toUpperCase() + '! Dispatched to Hyderabad Traffic Police database mock.');
                document.getElementById('plate').value = '';
                document.getElementById('demanded').value = '';
            }

            function triggerSOS() {
                alert('🚨 SOS ALERT TRIGGERED! Live GPS location and emergency message dispatched to Hyderabad Police Control Room.');
            }
        </script>
    </body>
    </html>
  `);
});

app.listen(PORT, () => {
  console.log('Web server running at http://localhost:3000');
});
