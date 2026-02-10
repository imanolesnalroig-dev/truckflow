/**
 * TruckFlow - European Truck Parking Data Seed Script
 *
 * Seeds the database with truck parking locations across major European corridors.
 * Data sources:
 * - Major autobahn rest areas (Germany)
 * - Truck parking on main transit routes (A1, A2, A4, E40, E75)
 * - Known secure parking facilities
 */

import postgres from 'postgres';

const sql = postgres(process.env.DATABASE_URL || 'postgres://truckflow:dev_password@localhost:5432/truckflow');

interface TruckPark {
  name: string;
  address: string;
  country: string;
  lat: number;
  lng: number;
  totalSpaces?: number;
  hasSecurity: boolean;
  hasCamera: boolean;
  hasFence: boolean;
  hasElectricity: boolean;
  hasWater: boolean;
  hasToilets: boolean;
  hasShowers: boolean;
  hasRestaurant: boolean;
  hasShop: boolean;
  hasAdblue: boolean;
  hasWifi: boolean;
  pricePerNightEur?: number;
  isFree: boolean;
}

// European Truck Parking Data - Major Corridors
const truckParks: TruckPark[] = [
  // Germany - A2 Corridor (Ruhr to Berlin)
  {
    name: 'Rasthof Helmstedt Nord',
    address: 'A2 km 242, 38350 Helmstedt',
    country: 'DE',
    lat: 52.2167,
    lng: 11.0167,
    totalSpaces: 150,
    hasSecurity: true,
    hasCamera: true,
    hasFence: true,
    hasElectricity: false,
    hasWater: false,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: true,
    pricePerNightEur: 15,
    isFree: false,
  },
  {
    name: 'Autohof Peine',
    address: 'Im Gewerbepark 15, 31228 Peine',
    country: 'DE',
    lat: 52.3167,
    lng: 10.2333,
    totalSpaces: 200,
    hasSecurity: true,
    hasCamera: true,
    hasFence: true,
    hasElectricity: true,
    hasWater: true,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: true,
    pricePerNightEur: 20,
    isFree: false,
  },
  // Germany - A1 Corridor (Hamburg to Cologne)
  {
    name: 'Rasthof Münsterland West',
    address: 'A1 km 268, 48268 Greven',
    country: 'DE',
    lat: 52.0833,
    lng: 7.6500,
    totalSpaces: 120,
    hasSecurity: false,
    hasCamera: true,
    hasFence: false,
    hasElectricity: false,
    hasWater: false,
    hasToilets: true,
    hasShowers: false,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: false,
    isFree: true,
  },
  // Poland - A2 Corridor (Border to Warsaw)
  {
    name: 'MOP Konin',
    address: 'A2 km 289, 62-510 Konin',
    country: 'PL',
    lat: 52.2167,
    lng: 18.2500,
    totalSpaces: 180,
    hasSecurity: true,
    hasCamera: true,
    hasFence: true,
    hasElectricity: false,
    hasWater: false,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: true,
    pricePerNightEur: 10,
    isFree: false,
  },
  {
    name: 'Truck Stop Koło',
    address: 'ul. Toruńska 200, 62-600 Koło',
    country: 'PL',
    lat: 52.2000,
    lng: 18.6333,
    totalSpaces: 100,
    hasSecurity: true,
    hasCamera: true,
    hasFence: true,
    hasElectricity: true,
    hasWater: true,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: true,
    pricePerNightEur: 8,
    isFree: false,
  },
  {
    name: 'MOP Baranów',
    address: 'A2 km 400, 63-604 Baranów',
    country: 'PL',
    lat: 51.9833,
    lng: 17.8667,
    totalSpaces: 90,
    hasSecurity: false,
    hasCamera: true,
    hasFence: false,
    hasElectricity: false,
    hasWater: false,
    hasToilets: true,
    hasShowers: false,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: false,
    hasWifi: false,
    isFree: true,
  },
  // Netherlands - A1/A28 Corridor
  {
    name: 'Truckparking Veenendaal',
    address: 'De Smalle Zijde 40, 3903 LP Veenendaal',
    country: 'NL',
    lat: 52.0167,
    lng: 5.5333,
    totalSpaces: 250,
    hasSecurity: true,
    hasCamera: true,
    hasFence: true,
    hasElectricity: true,
    hasWater: true,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: false,
    hasShop: false,
    hasAdblue: false,
    hasWifi: true,
    pricePerNightEur: 25,
    isFree: false,
  },
  {
    name: 'De Bolder Truck Parking',
    address: 'Energieweg 2, 3542 DZ Utrecht',
    country: 'NL',
    lat: 52.1000,
    lng: 5.0333,
    totalSpaces: 180,
    hasSecurity: true,
    hasCamera: true,
    hasFence: true,
    hasElectricity: true,
    hasWater: true,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: true,
    pricePerNightEur: 28,
    isFree: false,
  },
  // Belgium - E40/A3 Corridor
  {
    name: 'Total Aire de Heverlee',
    address: 'E40 km 23, 3001 Heverlee',
    country: 'BE',
    lat: 50.8667,
    lng: 4.6833,
    totalSpaces: 80,
    hasSecurity: false,
    hasCamera: true,
    hasFence: false,
    hasElectricity: false,
    hasWater: false,
    hasToilets: true,
    hasShowers: false,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: false,
    isFree: true,
  },
  // France - A1 Corridor (Paris to Lille)
  {
    name: 'Aire de Ressons-Ouest',
    address: 'A1 km 90, 60490 Ressons-sur-Matz',
    country: 'FR',
    lat: 49.5500,
    lng: 2.7500,
    totalSpaces: 200,
    hasSecurity: true,
    hasCamera: true,
    hasFence: true,
    hasElectricity: false,
    hasWater: false,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: true,
    pricePerNightEur: 18,
    isFree: false,
  },
  // Spain - A2/E90 Corridor (Barcelona to Madrid)
  {
    name: 'Área de Servicio La Junquera',
    address: 'AP-7 km 2, 17700 La Jonquera',
    country: 'ES',
    lat: 42.4167,
    lng: 2.8667,
    totalSpaces: 300,
    hasSecurity: true,
    hasCamera: true,
    hasFence: true,
    hasElectricity: true,
    hasWater: true,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: true,
    pricePerNightEur: 22,
    isFree: false,
  },
  {
    name: 'Área de Servicio Lleida',
    address: 'A-2 km 457, 25190 Lleida',
    country: 'ES',
    lat: 41.6167,
    lng: 0.6333,
    totalSpaces: 150,
    hasSecurity: true,
    hasCamera: true,
    hasFence: true,
    hasElectricity: false,
    hasWater: false,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: true,
    pricePerNightEur: 15,
    isFree: false,
  },
  // Italy - A1 Corridor (Milan to Rome)
  {
    name: 'Area di Servizio Secchia Ovest',
    address: 'A1 km 162, 41058 Vignola',
    country: 'IT',
    lat: 44.4500,
    lng: 11.0000,
    totalSpaces: 180,
    hasSecurity: true,
    hasCamera: true,
    hasFence: true,
    hasElectricity: false,
    hasWater: false,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: true,
    pricePerNightEur: 20,
    isFree: false,
  },
  // Austria - A1/E60 Brenner Corridor
  {
    name: 'Truckparkplatz Innsbruck',
    address: 'Grabenweg 68, 6020 Innsbruck',
    country: 'AT',
    lat: 47.2500,
    lng: 11.3833,
    totalSpaces: 120,
    hasSecurity: true,
    hasCamera: true,
    hasFence: true,
    hasElectricity: true,
    hasWater: true,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: false,
    hasShop: false,
    hasAdblue: false,
    hasWifi: true,
    pricePerNightEur: 30,
    isFree: false,
  },
  // Czech Republic - D1 Corridor (Prague to Brno)
  {
    name: 'OMV Čerpací stanice Velká Bíteš',
    address: 'D1 km 153, 595 01 Velká Bíteš',
    country: 'CZ',
    lat: 49.2833,
    lng: 16.2167,
    totalSpaces: 100,
    hasSecurity: false,
    hasCamera: true,
    hasFence: false,
    hasElectricity: false,
    hasWater: false,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: false,
    isFree: true,
  },
  // Hungary - M1 Corridor (Budapest to Vienna)
  {
    name: 'MOL Töltőállomás Győr',
    address: 'M1 km 108, 9024 Győr',
    country: 'HU',
    lat: 47.6833,
    lng: 17.6333,
    totalSpaces: 130,
    hasSecurity: true,
    hasCamera: true,
    hasFence: true,
    hasElectricity: false,
    hasWater: false,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: true,
    pricePerNightEur: 12,
    isFree: false,
  },
  // Romania - A1 Corridor (Bucharest to Sibiu)
  {
    name: 'Petrom Peco Pitești',
    address: 'A1 km 109, 110224 Pitești',
    country: 'RO',
    lat: 44.8500,
    lng: 24.8667,
    totalSpaces: 80,
    hasSecurity: true,
    hasCamera: true,
    hasFence: true,
    hasElectricity: false,
    hasWater: false,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: true,
    pricePerNightEur: 8,
    isFree: false,
  },
  // Bulgaria - A1/E80 Corridor
  {
    name: 'OMV Benzиностанция Плова',
    address: 'A1 km 132, 4000 Plovdiv',
    country: 'BG',
    lat: 42.1500,
    lng: 24.7500,
    totalSpaces: 70,
    hasSecurity: true,
    hasCamera: true,
    hasFence: true,
    hasElectricity: false,
    hasWater: false,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: false,
    pricePerNightEur: 6,
    isFree: false,
  },
  // Lithuania - A1 Corridor (Vilnius to Klaipėda)
  {
    name: 'Circle K Truck Stop Kaunas',
    address: 'A1 km 102, 54340 Kaunas',
    country: 'LT',
    lat: 54.9000,
    lng: 23.9000,
    totalSpaces: 100,
    hasSecurity: true,
    hasCamera: true,
    hasFence: true,
    hasElectricity: false,
    hasWater: false,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: true,
    pricePerNightEur: 10,
    isFree: false,
  },
  // Turkey - E80/TEM Corridor
  {
    name: 'Opet Petrol Edirne',
    address: 'D100 km 5, 22030 Edirne',
    country: 'TR',
    lat: 41.6667,
    lng: 26.5500,
    totalSpaces: 200,
    hasSecurity: true,
    hasCamera: true,
    hasFence: true,
    hasElectricity: false,
    hasWater: false,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: true,
    pricePerNightEur: 5,
    isFree: false,
  },
  // More Free Rest Areas
  {
    name: 'Rastplatz Börde Nord',
    address: 'A2 km 153, 39167 Irxleben',
    country: 'DE',
    lat: 52.1500,
    lng: 11.4833,
    totalSpaces: 60,
    hasSecurity: false,
    hasCamera: false,
    hasFence: false,
    hasElectricity: false,
    hasWater: false,
    hasToilets: true,
    hasShowers: false,
    hasRestaurant: false,
    hasShop: false,
    hasAdblue: false,
    hasWifi: false,
    isFree: true,
  },
  {
    name: 'MOP Kępno',
    address: 'S8 km 178, 63-600 Kępno',
    country: 'PL',
    lat: 51.2833,
    lng: 17.9833,
    totalSpaces: 50,
    hasSecurity: false,
    hasCamera: false,
    hasFence: false,
    hasElectricity: false,
    hasWater: false,
    hasToilets: true,
    hasShowers: false,
    hasRestaurant: false,
    hasShop: false,
    hasAdblue: false,
    hasWifi: false,
    isFree: true,
  },
  {
    name: 'Área de Descanso Zaragoza',
    address: 'A-2 km 315, 50014 Zaragoza',
    country: 'ES',
    lat: 41.6500,
    lng: -0.8833,
    totalSpaces: 80,
    hasSecurity: false,
    hasCamera: true,
    hasFence: false,
    hasElectricity: false,
    hasWater: false,
    hasToilets: true,
    hasShowers: false,
    hasRestaurant: false,
    hasShop: false,
    hasAdblue: false,
    hasWifi: false,
    isFree: true,
  },
  // UK - M1/A1 Corridor
  {
    name: 'Truckhaven Lymm Services',
    address: 'M6 J20, Lymm WA13 0SP',
    country: 'GB',
    lat: 53.3833,
    lng: -2.4667,
    totalSpaces: 120,
    hasSecurity: true,
    hasCamera: true,
    hasFence: true,
    hasElectricity: true,
    hasWater: true,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: true,
    pricePerNightEur: 30,
    isFree: false,
  },
  {
    name: 'Donington Park Services',
    address: 'A50/M1, Castle Donington DE74 2TN',
    country: 'GB',
    lat: 52.8333,
    lng: -1.3667,
    totalSpaces: 200,
    hasSecurity: true,
    hasCamera: true,
    hasFence: true,
    hasElectricity: true,
    hasWater: true,
    hasToilets: true,
    hasShowers: true,
    hasRestaurant: true,
    hasShop: true,
    hasAdblue: true,
    hasWifi: true,
    pricePerNightEur: 28,
    isFree: false,
  },
];

async function seedTruckParks() {
  console.log('🚛 Seeding European truck parking data...\n');

  let inserted = 0;
  let skipped = 0;

  for (const park of truckParks) {
    try {
      // Check if already exists (by name and country)
      const existing = await sql`
        SELECT id FROM truck_parks
        WHERE name = ${park.name} AND country = ${park.country}
      `;

      if (existing.length > 0) {
        console.log(`⏭️  Skipped (exists): ${park.name}`);
        skipped++;
        continue;
      }

      // Insert new truck park
      await sql`
        INSERT INTO truck_parks (
          name, address, country, location, total_spaces,
          has_security, has_camera, has_fence, has_electricity, has_water,
          has_toilets, has_showers, has_restaurant, has_shop, has_adblue, has_wifi,
          price_per_night_eur, is_free, created_at
        ) VALUES (
          ${park.name},
          ${park.address},
          ${park.country},
          ST_MakePoint(${park.lng}, ${park.lat})::geography,
          ${park.totalSpaces || null},
          ${park.hasSecurity},
          ${park.hasCamera},
          ${park.hasFence},
          ${park.hasElectricity},
          ${park.hasWater},
          ${park.hasToilets},
          ${park.hasShowers},
          ${park.hasRestaurant},
          ${park.hasShop},
          ${park.hasAdblue},
          ${park.hasWifi},
          ${park.pricePerNightEur || null},
          ${park.isFree},
          NOW()
        )
      `;

      console.log(`✅ Inserted: ${park.name} (${park.country})`);
      inserted++;
    } catch (error) {
      console.error(`❌ Failed: ${park.name}:`, error);
    }
  }

  console.log(`\n📊 Summary:`);
  console.log(`   Inserted: ${inserted}`);
  console.log(`   Skipped:  ${skipped}`);
  console.log(`   Total:    ${truckParks.length}`);
}

async function main() {
  try {
    await seedTruckParks();
  } catch (error) {
    console.error('Seeding failed:', error);
    process.exit(1);
  } finally {
    await sql.end();
  }
}

main();
