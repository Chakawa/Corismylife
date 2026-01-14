const axios = require('axios');

async function testAPI() {
  try {
    const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MzEsImVtYWlsIjoic3VwZXJfYWRtaW5AY29yaXMuY2kiLCJyb2xlIjoic3VwZXJfYWRtaW4iLCJjb2RlX2FwcG9ydGV1ciI6bnVsbCwiaWF0IjoxNzY4NDA1NzU5LCJleHAiOjE3NzA5OTc3NTl9.Aygf1fsEokOYeW2dKlIqrobGYuH7kqNp--ed0e2fbak';
    
    console.log('🔍 Test endpoint: http://127.0.0.1:5000/api/admin/stats/connexions-mensuelles\n');
    
    const response = await axios.get('http://127.0.0.1:5000/api/admin/stats/connexions-mensuelles', {
      params: { months: 12 },
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('✅ Status:', response.status);
    console.log('📦 Data:', JSON.stringify(response.data, null, 2));
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    }
  }
}

testAPI();
