const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const pool = require('../db');

// ==========================================
// CORIS SÉRÉNITÉ - Données complètes
// ==========================================
const tarifaireSerenite = {
  18: {12: 211.06800, 24: 107.68200, 36: 73.24810, 48: 56.05140, 60: 45.74950, 72: 38.89480, 84: 34.01000, 96: 30.35640, 108: 27.52380, 120: 25.26600, 132: 23.42630, 144: 21.90040, 156: 20.61590, 168: 19.52110, 180: 18.57825},
  19: {12: 216.61200, 24: 110.52000, 36: 75.18300, 48: 57.53470, 60: 46.96180, 72: 39.92650, 84: 34.91300, 96: 31.16320, 108: 28.25590, 120: 25.93870, 132: 24.05060, 144: 22.48460, 156: 21.16630, 168: 20.04280, 180: 19.07518},
  20: {12: 222.21500, 24: 113.38400, 36: 77.13450, 48: 59.02970, 60: 48.18310, 72: 40.96580, 84: 35.82240, 96: 31.97560, 108: 28.99320, 120: 26.61610, 132: 24.67930, 144: 23.07280, 156: 21.72050, 168: 20.56810, 180: 19.57567},
  21: {12: 227.94000, 24: 116.30900, 36: 79.12570, 48: 60.55470, 60: 49.42870, 72: 42.02550, 84: 36.74990, 96: 32.80410, 108: 29.74510, 120: 27.30690, 132: 25.32040, 144: 23.67270, 156: 22.28580, 168: 21.10400, 180: 20.08639},
  22: {12: 233.82400, 24: 119.31300, 36: 81.17100, 48: 62.12090, 60: 50.70800, 72: 43.11410, 84: 37.70250, 96: 33.65520, 108: 30.51750, 120: 28.01670, 132: 25.97920, 144: 24.28920, 156: 22.86690, 168: 21.65490, 180: 20.61152},
  23: {12: 239.89500, 24: 122.41300, 36: 83.28110, 48: 63.73690, 60: 52.02820, 72: 44.23750, 84: 38.68590, 96: 34.53380, 108: 31.31500, 120: 28.74950, 132: 26.65930, 144: 24.92590, 156: 23.46700, 168: 22.22420, 180: 21.15425},
  24: {12: 246.16700, 24: 125.61600, 36: 85.46130, 48: 65.40690, 60: 53.39260, 72: 45.39870, 84: 39.70230, 96: 35.44210, 108: 32.13930, 120: 29.50710, 132: 27.36270, 144: 25.58440, 156: 24.08810, 168: 22.81330, 180: 21.71614},
  25: {12: 252.64000, 24: 128.92100, 36: 87.71220, 48: 67.13130, 60: 54.80160, 72: 46.59800, 84: 40.75220, 96: 36.38020, 108: 32.99090, 120: 30.28990, 132: 28.08970, 144: 26.26530, 156: 24.73030, 168: 23.42280, 180: 22.29758},
  26: {12: 259.32200, 24: 132.33400, 36: 90.03680, 48: 68.91220, 60: 56.25700, 72: 47.83670, 84: 41.83660, 96: 37.34930, 108: 33.87090, 120: 31.09900, 132: 28.84140, 144: 26.96950, 156: 25.39470, 168: 24.05360, 180: 22.89959},
  27: {12: 266.20900, 24: 135.85200, 36: 92.43290, 48: 70.74800, 60: 57.75720, 72: 49.11370, 84: 42.95460, 96: 38.34870, 108: 34.77870, 120: 31.93410, 132: 29.61730, 144: 27.69670, 156: 26.08110, 168: 24.70550, 180: 23.52198},
  28: {12: 273.30600, 24: 139.47800, 36: 94.90250, 48: 72.64020, 60: 59.30350, 72: 50.43000, 84: 44.10740, 96: 39.37970, 108: 35.71540, 120: 32.79600, 132: 30.41860, 144: 28.44800, 156: 26.79050, 168: 25.37950, 180: 24.16587},
  29: {12: 280.62500, 24: 143.21700, 36: 97.44940, 48: 74.59150, 60: 60.89840, 72: 51.78820, 84: 45.29750, 96: 40.44430, 108: 36.68320, 120: 33.68690, 132: 31.24710, 144: 29.22500, 156: 27.52460, 168: 26.07730, 180: 24.83289},
  30: {12: 288.16900, 24: 147.07100, 36: 100.07400, 48: 76.60310, 60: 62.54320, 72: 53.18970, 84: 46.52590, 96: 41.54370, 108: 37.68300, 120: 34.60750, 132: 32.10370, 144: 30.02890, 156: 28.28450, 168: 26.80010, 180: 25.52410},
  31: {12: 295.95200, 24: 151.04700, 36: 102.78300, 48: 78.67990, 60: 64.24240, 72: 54.63810, 84: 47.79610, 96: 42.68100, 108: 38.71760, 120: 35.56080, 132: 32.99110, 144: 30.86210, 156: 29.07260, 168: 27.55020, 180: 26.24177},
  32: {12: 303.98700, 24: 155.15400, 36: 105.58300, 48: 80.82820, 60: 66.00080, 72: 56.13770, 84: 49.11180, 96: 43.85960, 108: 39.79030, 120: 36.54970, 132: 33.91220, 144: 31.72750, 156: 29.89160, 168: 28.33010, 180: 26.98841},
  33: {12: 312.26000, 24: 159.38500, 36: 108.47000, 48: 83.04420, 60: 67.81560, 72: 57.68600, 84: 50.47070, 96: 45.07750, 108: 40.89950, 120: 37.57290, 132: 34.86590, 144: 32.62410, 156: 30.74060, 168: 29.13890, 180: 27.76314},
  34: {12: 320.75900, 24: 163.73600, 36: 111.43900, 48: 85.32440, 60: 69.68360, 72: 59.28050, 84: 51.87090, 96: 46.33310, 108: 42.04390, 120: 38.62910, 132: 35.85100, 144: 33.55070, 156: 31.61850, 168: 29.97590, 180: 28.56511},
  35: {12: 329.46100, 24: 168.19100, 36: 114.48100, 48: 87.66120, 60: 71.59900, 72: 60.91620, 84: 53.30830, 96: 47.62310, 108: 43.22030, 120: 39.71570, 132: 36.86500, 144: 34.50520, 156: 32.52330, 168: 30.83870, 180: 29.39225},
  36: {12: 338.37900, 24: 172.75900, 36: 117.60100, 48: 90.05950, 60: 73.56580, 72: 62.59710, 84: 54.78660, 96: 48.95070, 108: 44.43180, 120: 40.83550, 132: 37.91070, 144: 35.49000, 156: 33.45730, 168: 31.72980, 180: 30.24666},
  37: {12: 347.50100, 24: 177.43300, 36: 120.79500, 48: 92.51630, 60: 75.58220, 72: 64.32190, 84: 56.30460, 96: 50.31490, 108: 45.67770, 120: 41.98780, 132: 38.98730, 144: 36.50430, 156: 34.41960, 168: 32.64820, 180: 31.12762},
  38: {12: 356.83100, 24: 182.21700, 36: 124.06700, 48: 95.03480, 60: 77.65130, 72: 66.09310, 84: 57.86460, 96: 51.71790, 108: 46.95980, 120: 43.17420, 132: 40.09630, 144: 37.54950, 156: 35.41160, 168: 33.59520, 180: 32.03636},
  39: {12: 366.36000, 24: 187.10700, 36: 127.41400, 48: 97.61420, 60: 79.77200, 72: 67.90990, 84: 59.46600, 96: 53.15910, 108: 48.27750, 120: 44.39420, 132: 41.23710, 144: 38.62500, 156: 36.43260, 168: 34.57030, 180: 32.97238},
  40: {12: 376.07300, 24: 192.09600, 36: 130.83400, 48: 100.25100, 60: 81.94180, 72: 69.77010, 84: 61.10670, 96: 54.63650, 108: 49.62890, 120: 45.64570, 132: 42.40770, 144: 39.72900, 156: 37.48110, 168: 35.57200, 180: 33.93432},
  41: {12: 385.95400, 24: 197.17900, 36: 134.32000, 48: 102.94200, 60: 84.15720, 72: 71.67080, 84: 62.78400, 96: 56.14740, 108: 51.01150, 120: 46.92640, 132: 43.60600, 144: 40.85960, 156: 38.55510, 168: 36.59850, 180: 34.92061},
  42: {12: 395.97400, 24: 202.33500, 36: 137.85900, 48: 105.67500, 60: 86.40960, 72: 73.60410, 84: 64.49080, 96: 57.68540, 108: 52.41920, 120: 48.23080, 132: 44.82690, 144: 42.01180, 156: 39.65040, 168: 37.64580, 180: 35.92736},
  43: {12: 406.13700, 24: 207.57000, 36: 141.45500, 48: 108.45400, 60: 88.70090, 72: 75.57160, 84: 66.22820, 96: 59.25130, 108: 53.85280, 120: 49.55970, 132: 46.07130, 144: 43.18690, 156: 40.76780, 168: 38.71490, 180: 36.95554},
  44: {12: 416.43500, 24: 212.87800, 36: 145.10300, 48: 111.27600, 60: 91.02750, 72: 77.56990, 84: 67.99310, 96: 60.84250, 108: 55.31010, 120: 50.91120, 132: 47.33730, 144: 44.38300, 156: 41.90590, 168: 39.80440, 180: 38.00430},
  45: {12: 426.86600, 24: 218.25800, 36: 148.80300, 48: 114.13800, 60: 93.38810, 72: 79.59760, 84: 69.78450, 96: 62.45810, 108: 56.79040, 120: 52.28470, 132: 48.62480, 144: 45.60010, 156: 43.06460, 168: 40.91470, 180: 39.07432},
  46: {12: 437.43000, 24: 223.70900, 36: 152.55200, 48: 117.03700, 60: 95.77990, 72: 81.65270, 84: 71.60080, 96: 64.09700, 108: 58.29290, 120: 53.67960, 132: 49.93320, 144: 46.83760, 156: 44.24410, 168: 42.04620, 180: 40.16657},
  47: {12: 448.14300, 24: 229.23600, 36: 156.35300, 48: 119.97800, 60: 98.20640, 72: 83.73850, 84: 73.44520, 96: 65.76230, 108: 59.82060, 120: 55.09890, 132: 51.26520, 144: 48.09900, 156: 45.44780, 168: 43.20310, 180: 41.28498},
  48: {12: 459.02900, 24: 234.85300, 36: 160.21700, 48: 122.96800, 60: 100.67500, 72: 85.86140, 84: 75.32370, 96: 67.45950, 108: 61.37870, 120: 56.54720, 132: 52.62620, 144: 49.38970, 156: 46.68180, 168: 44.39100, 180: 42.43567},
  49: {12: 470.11200, 24: 240.57300, 36: 164.15300, 48: 126.01500, 60: 103.19200, 72: 88.02790, 84: 77.24220, 96: 69.19400, 108: 62.97210, 120: 58.03060, 132: 54.02220, 144: 50.71620, 156: 47.95230, 168: 45.61650, 180: 43.62498},
  50: {12: 481.40700, 24: 246.40400, 36: 168.16800, 48: 129.12600, 60: 105.76400, 72: 90.24350, 84: 79.20550, 96: 70.97040, 108: 64.60640, 120: 59.55440, 132: 55.45940, 144: 52.08430, 156: 49.26550, 168: 46.88570, 180: 44.85898},
  51: {12: 492.93300, 24: 252.36000, 36: 172.27300, 48: 132.30900, 60: 108.39800, 72: 92.51390, 84: 81.21900, 96: 72.79510, 108: 66.28800, 120: 61.12590, 132: 56.94450, 144: 53.50140, 156: 50.62850, 168: 48.20560, 180: 46.14489},
  52: {12: 504.68700, 24: 258.43900, 36: 176.46500, 48: 135.56300, 60: 111.09200, 72: 94.83850, 84: 83.28410, 96: 74.67020, 108: 68.02050, 120: 62.74860, 132: 58.48180, 144: 54.97150, 156: 52.04530, 168: 49.58050, 180: 47.48711},
  53: {12: 516.67100, 24: 264.64200, 36: 180.74700, 48: 138.89000, 60: 113.84900, 72: 97.22130, 84: 85.40560, 96: 76.60190, 108: 69.80940, 120: 64.42850, 132: 60.07710, 144: 56.50020, 156: 53.52200, 168: 51.01660, 180: 48.89180},
  54: {12: 528.89400, 24: 270.97500, 36: 185.12300, 48: 142.29100, 60: 116.67400, 72: 99.66970, 84: 87.59210, 96: 78.59780, 108: 71.66320, 120: 66.17370, 132: 61.73790, 144: 58.09560, 156: 55.06650, 168: 52.52160, 180: 50.36610},
  55: {12: 541.35700, 24: 277.43700, 36: 189.59100, 48: 145.77400, 60: 119.57500, 72: 102.19200, 84: 89.85100, 96: 80.66620, 108: 73.58930, 120: 67.99110, 132: 63.47190, 144: 59.76500, 156: 56.68600, 168: 54.10220, 180: 51.91669},
  56: {12: 554.07200, 24: 284.03500, 36: 194.17000, 48: 149.35500, 60: 122.56900, 72: 104.80300, 84: 92.19700, 96: 82.82020, 108: 75.59980, 120: 69.89310, 132: 65.29070, 144: 61.51990, 156: 58.39080, 168: 55.76840, 180: 53.55500},
  57: {12: 567.05400, 24: 290.80600, 36: 198.88500, 48: 153.05900, 60: 125.67600, 72: 107.52200, 84: 94.64660, 96: 85.07440, 108: 77.70940, 120: 71.89340, 132: 67.20760, 144: 63.37190, 156: 60.19260, 168: 57.53200, 180: 55.28909},
  58: {12: 580.21200, 24: 297.69100, 36: 203.70400, 48: 156.85500, 60: 128.87200, 72: 110.32700, 84: 97.18040, 96: 87.41320, 108: 79.90370, 120: 73.97890, 132: 69.20920, 144: 65.30880, 156: 62.08030, 168: 59.38280, 180: 57.11341},
  59: {12: 593.50900, 24: 304.69300, 36: 208.61800, 48: 160.74400, 60: 132.15600, 72: 113.21700, 84: 99.79840, 96: 89.83600, 108: 82.18250, 120: 76.14820, 132: 71.29480, 144: 67.33070, 156: 64.05420, 168: 61.32180, 180: 59.02823},
  60: {12: 606.85200, 24: 311.73100, 36: 213.58200, 48: 164.68400, 60: 135.49200, 72: 116.16300, 84: 102.47600, 96: 92.32130, 108: 84.52440, 120: 78.38200, 132: 73.44680, 144: 69.42130, 156: 66.09980, 168: 63.33560, 180: 61.02108},
  61: {12: 620.25600, 24: 318.84800, 36: 218.61900, 48: 168.69300, 60: 138.90000, 72: 119.18300, 84: 105.22800, 96: 94.88010, 108: 86.94020, 120: 80.69090, 132: 75.67610, 144: 71.59190, 156: 68.22830, 168: 65.43550, 180: 63.10365},
  62: {12: 633.63700, 24: 325.97100, 36: 223.67300, 48: 172.73400, 60: 142.34800, 72: 122.24700, 84: 108.02700, 96: 97.48830, 108: 89.40850, 120: 83.05610, 132: 77.96560, 144: 73.82680, 156: 70.42550, 168: 67.60860, 180: 65.26436},
  63: {12: 647.00600, 24: 333.10700, 36: 228.76400, 48: 176.82200, 60: 145.84900, 72: 125.36500, 84: 110.88100, 96: 100.15400, 108: 91.93770, 120: 85.48630, 132: 80.32440, 144: 76.13560, 156: 72.70120, 168: 69.86540, 180: 67.51454},
  64: {12: 660.38000, 24: 340.30200, 36: 233.92000, 48: 180.97700, 60: 149.41200, 72: 128.54500, 84: 113.79900, 96: 102.88700, 108: 94.53910, 120: 87.99290, 132: 82.76410, 144: 78.53010, 156: 75.06810, 168: 72.21950, 180: 69.86839},
  65: {12: 673.67800, 24: 347.48000, 36: 239.08500, 48: 185.14400, 60: 152.99500, 72: 131.75200, 84: 116.75200, 96: 105.66300, 108: 97.18920, 120: 90.55490, 132: 85.26590, 144: 80.99380, 156: 77.51160, 168: 74.65800, 180: 72.31495},
  66: {12: 686.91700, 24: 354.66200, 36: 244.25400, 48: 189.32600, 60: 156.60200, 72: 134.99300, 84: 119.74800, 96: 108.48900, 108: 99.89770, 120: 93.18270, 132: 87.84130, 144: 83.53920, 156: 80.04540, 168: 77.19570, 180: 74.87075},
  67: {12: 700.09300, 24: 361.79700, 36: 249.40700, 48: 193.51100, 60: 160.22800, 72: 138.26700, 84: 122.78600, 96: 111.36700, 108: 102.66700, 120: 95.88050, 132: 90.49600, 144: 86.17340, 156: 82.67810, 168: 79.84350, 180: 77.54916},
  68: {12: 713.31000, 24: 368.99300, 36: 254.62900, 48: 197.77400, 60: 163.94000, 72: 141.63100, 84: 125.92200, 96: 114.34900, 108: 105.54700, 120: 98.69720, 132: 93.27840, 144: 88.94510, 156: 85.45940, 168: 82.65290, 180: 80.40312},
  69: {12: 726.55800, 24: 376.24800, 36: 259.92400, 48: 202.11900, 60: 167.74100, 72: 145.09200, 84: 129.16100, 96: 117.44300, 108: 108.54800, 120: 101.64400, 132: 96.20200, 144: 91.87040, 156: 88.40870, 168: 85.64590, 180: 83.45695}
};

async function migrateSerenite() {
  try {
    let result = await pool.query('SELECT id FROM produit WHERE libelle = $1', ['CORIS SÉRÉNITÉ']);
    let produitId;
    
    if (result.rows.length === 0) {
      result = await pool.query('INSERT INTO produit (libelle) VALUES ($1) RETURNING id', ['CORIS SÉRÉNITÉ']);
      produitId = result.rows[0].id;
      console.log('✅ Produit CORIS SÉRÉNITÉ créé avec l\'id:', produitId);
    } else {
      produitId = result.rows[0].id;
      console.log('✅ Produit CORIS SÉRÉNITÉ existe déjà avec l\'id:', produitId);
    }

    await pool.query('DELETE FROM tarif_produit WHERE produit_id = $1', [produitId]);

    const tarifs = [];
    for (const [age, durees] of Object.entries(tarifaireSerenite)) {
      for (const [duree, prime] of Object.entries(durees)) {
        tarifs.push({
          produit_id: produitId,
          duree_contrat: parseInt(duree),
          periodicite: 'annuel',
          prime: parseFloat(prime),
          age: parseInt(age),
        });
      }
    }

    const batchSize = 100;
    for (let i = 0; i < tarifs.length; i += batchSize) {
      const batch = tarifs.slice(i, i + batchSize);
      const values = [];
      const params = [];
      
      batch.forEach((t, idx) => {
        const base = idx * 5;
        values.push(`($${base + 1}, $${base + 2}, $${base + 3}, $${base + 4}, $${base + 5})`);
        params.push(t.produit_id, t.duree_contrat, t.periodicite, t.prime, t.age);
      });
      
      await pool.query(
        `INSERT INTO tarif_produit (produit_id, duree_contrat, periodicite, prime, age)
         VALUES ${values.join(', ')}`,
        params
      );
    }

    console.log(`✅ ${tarifs.length} tarifs CORIS SÉRÉNITÉ insérés avec succès`);
    return { produitId, count: tarifs.length };
  } catch (error) {
    console.error('❌ Erreur lors de la migration CORIS SÉRÉNITÉ:', error);
    throw error;
  }
}

// ==========================================
// Charge les données Familis depuis le fichier externe
// ==========================================
const familisData = require('./data/familis_data.json');

async function migrateFamilis() {
  console.log('Migrating CORIS FAMILIS data...');
  
  try {
    let result = await pool.query('SELECT id FROM produit WHERE libelle = $1', ['CORIS FAMILIS']);
    let produitId;
    
    if (result.rows.length === 0) {
      result = await pool.query('INSERT INTO produit (libelle) VALUES ($1) RETURNING id', ['CORIS FAMILIS']);
      produitId = result.rows[0].id;
      console.log('✅ Produit CORIS FAMILIS créé avec l\'id:', produitId);
    } else {
      produitId = result.rows[0].id;
      console.log('✅ Produit CORIS FAMILIS existe déjà avec l\'id:', produitId);
    }

    await pool.query('DELETE FROM tarif_produit WHERE produit_id = $1', [produitId]);

    const tarifs = [];

    // Taux Unique
    for (const [age, durees] of Object.entries(familisData.tauxUnique)) {
      for (const [duree, taux] of Object.entries(durees)) {
        tarifs.push({
          produit_id: produitId,
          duree_contrat: parseInt(duree),
          periodicite: 'unique',
          prime: parseFloat(taux),
          age: parseInt(age),
        });
      }
    }

    // Taux Annuel
    for (const [age, durees] of Object.entries(familisData.tauxAnnuel)) {
      for (const [duree, taux] of Object.entries(durees)) {
        tarifs.push({
          produit_id: produitId,
          duree_contrat: parseInt(duree),
          periodicite: 'annuel',
          prime: parseFloat(taux),
          age: parseInt(age),
        });
      }
    }

    const batchSize = 100;
    for (let i = 0; i < tarifs.length; i += batchSize) {
      const batch = tarifs.slice(i, i + batchSize);
      const values = [];
      const params = [];
      
      batch.forEach((t, idx) => {
        const base = idx * 5;
        values.push(`($${base + 1}, $${base + 2}, $${base + 3}, $${base + 4}, $${base + 5})`);
        params.push(t.produit_id, t.duree_contrat, t.periodicite, t.prime, t.age);
      });
      
      await pool.query(
        `INSERT INTO tarif_produit (produit_id, duree_contrat, periodicite, prime, age)
         VALUES ${values.join(', ')}`,
        params
      );
    }

    console.log(`✅ ${tarifs.length} tarifs CORIS FAMILIS insérés avec succès`);
    return { produitId, count: tarifs.length };
  } catch (error) {
    console.error('❌ Erreur lors de la migration CORIS FAMILIS:', error);
    throw error;
  }
}

// ==========================================
// CORIS RETRAITE - Données premiumValues
// ==========================================
async function migrateRetraite() {
  console.log('Migrating CORIS RETRAITE data...');
  
  const premiumValues = {
    5: { mensuel: 17385.55245, trimestriel: 51343.16466, semestriel: 101813.14352, annuel: 201890.00380 },
    6: { mensuel: 14238.32819, trimestriel: 41978.94598, semestriel: 83298.26868, annuel: 165175.99987 },
    7: { mensuel: 11992.86563, trimestriel: 35424.10172, semestriel: 70323.54417, annuel: 139011.72433 },
    8: { mensuel: 10311.00079, trimestriel: 30413.27008, semestriel: 60397.20310, annuel: 119431.37050 },
    9: { mensuel: 9004.86435, trimestriel: 26529.29040, semestriel: 52698.35344, annuel: 104235.51451 },
    10: { mensuel: 7563.64759, trimestriel: 22312.00493, semestriel: 44228.31611, annuel: 87500.89678 },
    11: { mensuel: 6754.38423, trimestriel: 19903.12711, semestriel: 39467.22927, annuel: 78095.31588 },
    12: { mensuel: 6081.40012, trimestriel: 17902.64892, semestriel: 35510.77460, annuel: 70276.78179 },
    13: { mensuel: 5513.24280, trimestriel: 16246.02984, semestriel: 32232.54909, annuel: 63796.71982 },
    14: { mensuel: 5027.44598, trimestriel: 14800.85821, semestriel: 29371.52796, annuel: 58140.14424 },
    15: { mensuel: 4607.53413, trimestriel: 13553.04544, semestriel: 26900.24228, annuel: 53253.15960 },
    16: { mensuel: 4234.30376, trimestriel: 12485.18488, semestriel: 24745.32809, annuel: 48991.07389 },
    17: { mensuel: 3906.76267, trimestriel: 11526.84218, semestriel: 22850.74160, annuel: 45243.31561 },
    18: { mensuel: 3617.16662, trimestriel: 10678.49023, semestriel: 21172.93236, annuel: 41923.93536 },
    19: { mensuel: 3359.42700, trimestriel: 9936.57609, semestriel: 19705.05837, annuel: 38965.11313 },
    20: { mensuel: 3128.69085, trimestriel: 9257.85305, semestriel: 18361.84334, annuel: 36312.61717 },
    21: { mensuel: 2921.04241, trimestriel: 8646.57304, semestriel: 17151.75590, annuel: 33922.56273 },
    22: { mensuel: 2733.28735, trimestriel: 8103.74654, semestriel: 16056.55640, annuel: 31759.05634 },
    23: { mensuel: 2562.79385, trimestriel: 7600.25802, semestriel: 15061.18718, annuel: 29792.45569 },
    24: { mensuel: 2407.37402, trimestriel: 7141.05329, semestriel: 14153.10752, annuel: 27998.06519 },
    25: { mensuel: 2265.19402, trimestriel: 6728.62923, semestriel: 13337.28607, annuel: 26385.73330 },
    26: { mensuel: 2134.70522, trimestriel: 6342.11478, semestriel: 12572.57942, annuel: 24874.28638 },
    27: { mensuel: 2014.59084, trimestriel: 5986.21186, semestriel: 11868.28274, annuel: 23482.08901 },
    28: { mensuel: 1903.72406, trimestriel: 5663.78043, semestriel: 11217.87997, annuel: 22196.29606 },
    29: { mensuel: 1801.13496, trimestriel: 5359.17421, semestriel: 10615.75618, annuel: 21005.83652 },
    30: { mensuel: 1705.98414, trimestriel: 5076.59191, semestriel: 10057.04697, annuel: 19901.11723 },
    31: { mensuel: 1617.54143, trimestriel: 4818.83139, semestriel: 9547.28012, annuel: 18873.78411 },
    32: { mensuel: 1535.16869, trimestriel: 4573.76738, semestriel: 9062.56656, annuel: 17916.52823 },
    33: { mensuel: 1458.30574, trimestriel: 4345.06312, semestriel: 8610.13211, annuel: 17022.92723 },
    34: { mensuel: 1386.45880, trimestriel: 4135.30013, semestriel: 8187.09854, annuel: 16187.31468 },
    35: { mensuel: 1319.19093, trimestriel: 3934.84048, semestriel: 7790.91726, annuel: 15404.67203 },
    36: { mensuel: 1256.11406, trimestriel: 3746.85383, semestriel: 7419.32336, annuel: 14670.53842 },
    37: { mensuel: 1196.88235, trimestriel: 3573.66135, semestriel: 7076.89185, annuel: 13993.93933 },
    38: { mensuel: 1141.18658, trimestriel: 3407.44859, semestriel: 6748.23829, annuel: 13344.54196 },
    39: { mensuel: 1088.74944, trimestriel: 3250.95304, semestriel: 6438.75443, annuel: 12732.97936 },
    40: { mensuel: 1039.32148, trimestriel: 3106.23686, semestriel: 6146.97839, annuel: 12156.37022 },
    41: { mensuel: 992.67774, trimestriel: 2966.86268, semestriel: 5871.59109, annuel: 11612.11433 },
    42: { mensuel: 948.61478, trimestriel: 2835.19736, semestriel: 5611.39921, annuel: 11097.85903 },
    43: { mensuel: 906.94817, trimestriel: 2713.06304, semestriel: 5369.98847, annuel: 10611.47043 },
    44: { mensuel: 867.51031, trimestriel: 2595.08784, semestriel: 5136.79219, annuel: 10151.00851 },
    45: { mensuel: 830.14858, trimestriel: 2483.32319, semestriel: 4915.84582, annuel: 9714.70556 },
    46: { mensuel: 794.72366, trimestriel: 2377.35238, semestriel: 4706.32965, annuel: 9300.94747 },
    47: { mensuel: 761.10815, trimestriel: 2276.79425, semestriel: 4507.49375, annuel: 8908.25736 },
    48: { mensuel: 729.18528, trimestriel: 2181.29955, semestriel: 4318.65075, annuel: 8535.28130 },
    49: { mensuel: 698.84787, trimestriel: 2090.54761, semestriel: 4142.58435, annuel: 8187.50292 },
    50: { mensuel: 669.99733, trimestriel: 2004.24351, semestriel: 3971.71793, annuel: 7849.99700 },
};

  try {
    let result = await pool.query('SELECT id FROM produit WHERE libelle = $1', ['CORIS RETRAITE']);
    let produitId;
    
    if (result.rows.length === 0) {
      result = await pool.query('INSERT INTO produit (libelle) VALUES ($1) RETURNING id', ['CORIS RETRAITE']);
      produitId = result.rows[0].id;
      console.log('✅ Produit CORIS RETRAITE créé avec l\'id:', produitId);
    } else {
      produitId = result.rows[0].id;
      console.log('✅ Produit CORIS RETRAITE existe déjà avec l\'id:', produitId);
    }

    await pool.query('DELETE FROM tarif_produit WHERE produit_id = $1', [produitId]);

    const tarifs = [];
    for (const [duree, periodicites] of Object.entries(premiumValues)) {
      for (const [periodicite, prime] of Object.entries(periodicites)) {
        tarifs.push({
          produit_id: produitId,
          duree_contrat: parseInt(duree),
          periodicite: periodicite,
          prime: parseFloat(prime),
          age: null,
          capital: null,
        });
      }
    }

    const batchSize = 100;
    for (let i = 0; i < tarifs.length; i += batchSize) {
      const batch = tarifs.slice(i, i + batchSize);
      const values = [];
      const params = [];
      
      batch.forEach((t, idx) => {
        const base = idx * 6;
        values.push(`($${base + 1}, $${base + 2}, $${base + 3}, $${base + 4}, $${base + 5}, $${base + 6})`);
        params.push(t.produit_id, t.duree_contrat, t.periodicite, t.prime, t.age, t.capital);
      });
      
      await pool.query(
        `INSERT INTO tarif_produit (produit_id, duree_contrat, periodicite, prime, age, capital)
         VALUES ${values.join(', ')}`,
        params
      );
    }

    console.log(`✅ ${tarifs.length} tarifs CORIS RETRAITE insérés avec succès`);
    return { produitId, count: tarifs.length };
  } catch (error) {
    console.error('❌ Erreur lors de la migration CORIS RETRAITE:', error);
    throw error;
  }
}

// ==========================================
// CORIS SOLIDARITÉ - Données avec catégories
// ==========================================
async function migrateSolidarite() {
  console.log('Migrating CORIS SOLIDARITÉ data...');
  
  const primeTotaleFamilleBase = {
    500000: { mensuel: 2699, trimestriel: 8019, semestriel: 15882, annuelle: 31141 },
    1000000: { mensuel: 5398, trimestriel: 16038, semestriel: 31764, annuelle: 62283 },
    1500000: { mensuel: 8097, trimestriel: 24057, semestriel: 47646, annuelle: 93424 },
    2000000: { mensuel: 10796, trimestriel: 32076, semestriel: 63529, annuelle: 124566 },
  };

  const surprimesConjointsSupplementaires = {
    500000: { mensuel: 860, trimestriel: 2555, semestriel: 5061, annuelle: 9924 },
    1000000: { mensuel: 1720, trimestriel: 5111, semestriel: 10123, annuelle: 19848 },
    1500000: { mensuel: 2580, trimestriel: 7666, semestriel: 15184, annuelle: 29773 },
    2000000: { mensuel: 3440, trimestriel: 10222, semestriel: 20245, annuelle: 39697 },
  };

  const surprimesEnfantsSupplementaires = {
    500000: { mensuel: 124, trimestriel: 370, semestriel: 732, annuelle: 1435 },
    1000000: { mensuel: 249, trimestriel: 739, semestriel: 1464, annuelle: 2870 },
    1500000: { mensuel: 373, trimestriel: 1109, semestriel: 2196, annuelle: 4306 },
    2000000: { mensuel: 498, trimestriel: 1478, semestriel: 2928, annuelle: 5741 },
  };

  const surprimesAscendants = {
    500000: { mensuel: 1547, trimestriel: 4596, semestriel: 9104, annuelle: 17850 },
    1000000: { mensuel: 3094, trimestriel: 9193, semestriel: 18207, annuelle: 35700 },
    1500000: { mensuel: 4641, trimestriel: 13789, semestriel: 27311, annuelle: 53550 },
    2000000: { mensuel: 6188, trimestriel: 18386, semestriel: 36414, annuelle: 71400 },
  };

  try {
    let result = await pool.query('SELECT id FROM produit WHERE libelle = $1', ['CORIS SOLIDARITÉ']);
    let produitId;
    
    if (result.rows.length === 0) {
      result = await pool.query('INSERT INTO produit (libelle) VALUES ($1) RETURNING id', ['CORIS SOLIDARITÉ']);
      produitId = result.rows[0].id;
      console.log('✅ Produit CORIS SOLIDARITÉ créé avec l\'id:', produitId);
    } else {
      produitId = result.rows[0].id;
      console.log('✅ Produit CORIS SOLIDARITÉ existe déjà avec l\'id:', produitId);
    }

    await pool.query('DELETE FROM tarif_produit WHERE produit_id = $1', [produitId]);

    const tarifs = [];

    // Famille de base
    for (const [capital, periodicites] of Object.entries(primeTotaleFamilleBase)) {
      for (const [periodicite, prime] of Object.entries(periodicites)) {
        tarifs.push({
          produit_id: produitId,
          duree_contrat: null,
          periodicite: periodicite === 'annuelle' ? 'annuel' : periodicite,
          prime: parseFloat(prime),
          capital: parseInt(capital),
          age: null,
          categorie: 'famille_base',
        });
      }
    }

    // Surprimes conjoints supplémentaires
    for (const [capital, periodicites] of Object.entries(surprimesConjointsSupplementaires)) {
      for (const [periodicite, prime] of Object.entries(periodicites)) {
        tarifs.push({
          produit_id: produitId,
          duree_contrat: null,
          periodicite: periodicite === 'annuelle' ? 'annuel' : periodicite,
          prime: parseFloat(prime),
          capital: parseInt(capital),
          age: null,
          categorie: 'avec_conjoint',
        });
      }
    }

    // Surprimes enfants supplémentaires
    for (const [capital, periodicites] of Object.entries(surprimesEnfantsSupplementaires)) {
      for (const [periodicite, prime] of Object.entries(periodicites)) {
        tarifs.push({
          produit_id: produitId,
          duree_contrat: null,
          periodicite: periodicite === 'annuelle' ? 'annuel' : periodicite,
          prime: parseFloat(prime),
          capital: parseInt(capital),
          age: null,
          categorie: 'avec_enfant',
        });
      }
    }

    // Surprimes ascendants
    for (const [capital, periodicites] of Object.entries(surprimesAscendants)) {
      for (const [periodicite, prime] of Object.entries(periodicites)) {
        tarifs.push({
          produit_id: produitId,
          duree_contrat: null,
          periodicite: periodicite === 'annuelle' ? 'annuel' : periodicite,
          prime: parseFloat(prime),
          capital: parseInt(capital),
          age: null,
          categorie: 'avec_ascendant',
        });
      }
    }

    const batchSize = 100;
    for (let i = 0; i < tarifs.length; i += batchSize) {
      const batch = tarifs.slice(i, i + batchSize);
      const values = [];
      const params = [];
      
      batch.forEach((t, idx) => {
        const base = idx * 7;
        values.push(`($${base + 1}, $${base + 2}, $${base + 3}, $${base + 4}, $${base + 5}, $${base + 6}, $${base + 7})`);
        params.push(t.produit_id, t.duree_contrat, t.periodicite, t.prime, t.capital, t.age, t.categorie);
      });
      
      await pool.query(
        `INSERT INTO tarif_produit (produit_id, duree_contrat, periodicite, prime, capital, age, categorie)
         VALUES ${values.join(', ')}`,
        params
      );
    }

    console.log(`✅ ${tarifs.length} tarifs CORIS SOLIDARITÉ insérés avec succès`);
    return { produitId, count: tarifs.length };
  } catch (error) {
    console.error('❌ Erreur lors de la migration CORIS SOLIDARITÉ:', error);
    throw error;
  }
}

// ==========================================
// Charge les données Etude depuis le fichier externe
// ==========================================
const etudeData = require('./data/etude_data.json');

async function migrateEtude() {
  console.log('Migrating CORIS ÉTUDE data...');
  
  try {
    let result = await pool.query('SELECT id FROM produit WHERE libelle = $1', ['CORIS ÉTUDE']);
    let produitId;
    
    if (result.rows.length === 0) {
      result = await pool.query('INSERT INTO produit (libelle) VALUES ($1) RETURNING id', ['CORIS ÉTUDE']);
      produitId = result.rows[0].id;
      console.log('✅ Produit CORIS ÉTUDE créé avec l\'id:', produitId);
    } else {
      produitId = result.rows[0].id;
      console.log('✅ Produit CORIS ÉTUDE existe déjà avec l\'id:', produitId);
    }

    await pool.query('DELETE FROM tarif_produit WHERE produit_id = $1', [produitId]);

    const tarifs = [];
    for (const [age, durees] of Object.entries(etudeData.tarifRenteFixe)) {
      for (const [duree, prime] of Object.entries(durees)) {
        tarifs.push({
          produit_id: produitId,
          duree_contrat: parseInt(duree),
          periodicite: 'annuel',
          prime: parseFloat(prime),
          age: parseInt(age),
        });
      }
    }

    const batchSize = 100;
    for (let i = 0; i < tarifs.length; i += batchSize) {
      const batch = tarifs.slice(i, i + batchSize);
      const values = [];
      const params = [];
      
      batch.forEach((t, idx) => {
        const base = idx * 5;
        values.push(`($${base + 1}, $${base + 2}, $${base + 3}, $${base + 4}, $${base + 5})`);
        params.push(t.produit_id, t.duree_contrat, t.periodicite, t.prime, t.age);
      });
      
      await pool.query(
        `INSERT INTO tarif_produit (produit_id, duree_contrat, periodicite, prime, age)
         VALUES ${values.join(', ')}`,
        params
      );
    }

    console.log(`✅ ${tarifs.length} tarifs CORIS ÉTUDE insérés avec succès`);
    return { produitId, count: tarifs.length };
  } catch (error) {
    console.error('❌ Erreur lors de la migration CORIS ÉTUDE:', error);
    throw error;
  }
}

// Fonction principale
async function main() {
  try {
    console.log('🚀 Démarrage de la migration des données produits...\n');
    
    await migrateSerenite();
    console.log('');
    await migrateFamilis();
    console.log('');
    await migrateRetraite();
    console.log('');
    await migrateSolidarite();
    console.log('');
    await migrateEtude();
    console.log('');
    await migrateFlexEmprunteur();
    
    console.log('\n✅ Migration terminée avec succès !');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Erreur lors de la migration:', error);
    process.exit(1);
  }
}

// Exécuter le script
if (require.main === module) {
  main();
}

// ==========================================
// CORIS FLEX EMPRUNTEUR - Données complètes
// ==========================================
// Note: Les données sont extraites du fichier flex_emprunteur_page.dart
// Format: { 'age_dureeMois': taux_pourcentage } où le taux est en pourcentage (ex: 0.150 = 0.15%)

async function migrateFlexEmprunteur() {
  console.log('Migrating CORIS FLEX EMPRUNTEUR data...');
  
  try {
    let result = await pool.query('SELECT id FROM produit WHERE libelle = $1', ['CORIS FLEX EMPRUNTEUR']);
    let produitId;
    
    if (result.rows.length === 0) {
      result = await pool.query('INSERT INTO produit (libelle) VALUES ($1) RETURNING id', ['CORIS FLEX EMPRUNTEUR']);
      produitId = result.rows[0].id;
      console.log('✅ Produit CORIS FLEX EMPRUNTEUR créé avec l\'id:', produitId);
    } else {
      produitId = result.rows[0].id;
      console.log('✅ Produit CORIS FLEX EMPRUNTEUR existe déjà avec l\'id:', produitId);
    }

    await pool.query('DELETE FROM tarif_produit WHERE produit_id = $1', [produitId]);

    const tarifs = [];

    // Données FLEX EMPRUNTEUR extraites du fichier flex_emprunteur_page.dart
    // Note: Les données complètes sont très volumineuses, on utilise un fichier JSON séparé
    // Structure attendue: { "tarifsPretAmortissable": {...}, "tarifsPretDecouvert": {...}, "tarifsPerteEmploi": {...} }
    
    let flexData;
    try {
      flexData = require('./data/flex_emprunteur_data.json');
      console.log('   📄 Données chargées depuis flex_emprunteur_data.json');
    } catch (e) {
      console.log('⚠️  Fichier flex_emprunteur_data.json non trouvé');
      console.log('   💡 Veuillez créer ce fichier avec les données extraites du code Dart');
      console.log('   💡 Structure: { "tarifsPretAmortissable": {...}, "tarifsPretDecouvert": {...}, "tarifsPerteEmploi": {...} }');
      return { produitId: null, count: 0 };
    }

    // Migrer tarifsPretAmortissable (catégorie: 'amortissable')
    console.log('   📊 Migration des tarifs Prêt Amortissable...');
    for (const [key, taux] of Object.entries(flexData.tarifsPretAmortissable || {})) {
      const [ageStr, dureeMoisStr] = key.split('_');
      const age = parseInt(ageStr);
      const dureeMois = parseInt(dureeMoisStr);
      
      tarifs.push({
        produit_id: produitId,
        duree_contrat: dureeMois,
        periodicite: 'unique', // Unique pour FLEX EMPRUNTEUR
        prime: parseFloat(taux), // Taux en pourcentage
        age: age,
        categorie: 'amortissable'
      });
    }

    // Migrer tarifsPretDecouvert (catégorie: 'decouvert')
    console.log('   📊 Migration des tarifs Prêt Découvert...');
    for (const [key, taux] of Object.entries(flexData.tarifsPretDecouvert || {})) {
      const [ageStr, dureeMoisStr] = key.split('_');
      const age = parseInt(ageStr);
      const dureeMois = parseInt(dureeMoisStr);
      
      tarifs.push({
        produit_id: produitId,
        duree_contrat: dureeMois,
        periodicite: 'unique',
        prime: parseFloat(taux), // Taux en pourcentage
        age: age,
        categorie: 'decouvert'
      });
    }

    // Migrer tarifsPerteEmploi (catégorie: 'perte_emploi')
    // Note: Pour perte emploi, duree_contrat est en ANNÉES, pas en mois
    console.log('   📊 Migration des tarifs Perte d\'Emploi...');
    for (const [dureeAnneesStr, montant] of Object.entries(flexData.tarifsPerteEmploi || {})) {
      const dureeAnnees = parseInt(dureeAnneesStr);
      
      tarifs.push({
        produit_id: produitId,
        duree_contrat: dureeAnnees, // En années pour perte emploi
        periodicite: 'unique',
        prime: parseFloat(montant), // Montant fixe
        age: null, // Perte emploi n'utilise pas l'âge
        categorie: 'perte_emploi'
      });
    }

    // Insertion par batch
    const batchSize = 100;
    for (let i = 0; i < tarifs.length; i += batchSize) {
      const batch = tarifs.slice(i, i + batchSize);
      const values = [];
      const params = [];
      
      batch.forEach((t, idx) => {
        const base = idx * 6;
        values.push(`($${base + 1}, $${base + 2}, $${base + 3}, $${base + 4}, $${base + 5}, $${base + 6})`);
        params.push(t.produit_id, t.duree_contrat, t.periodicite, t.prime, t.age, t.categorie);
      });
      
      await pool.query(
        `INSERT INTO tarif_produit (produit_id, duree_contrat, periodicite, prime, age, categorie)
         VALUES ${values.join(', ')}`,
        params
      );
    }

    console.log(`✅ ${tarifs.length} tarifs CORIS FLEX EMPRUNTEUR insérés avec succès`);
    console.log(`   - Prêt Amortissable: ${Object.keys(flexData.tarifsPretAmortissable || {}).length} tarifs`);
    console.log(`   - Prêt Découvert: ${Object.keys(flexData.tarifsPretDecouvert || {}).length} tarifs`);
    console.log(`   - Perte d'Emploi: ${Object.keys(flexData.tarifsPerteEmploi || {}).length} tarifs`);
    
    return { produitId, count: tarifs.length };
  } catch (error) {
    console.error('❌ Erreur lors de la migration CORIS FLEX EMPRUNTEUR:', error);
    throw error;
  }
}

module.exports = { migrateSerenite, migrateFamilis, migrateRetraite, migrateSolidarite, migrateEtude, migrateFlexEmprunteur };
