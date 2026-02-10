import { Kafka, Producer, Consumer, logLevel } from 'kafkajs';
import { config } from './index.js';

let kafka: Kafka;
let producer: Producer;
let consumer: Consumer;

// Kafka topics
export const TOPICS = {
  GPS_RAW: 'gps-raw',
  ACTIVITY_EVENTS: 'activity-events',
  HAZARD_EVENTS: 'hazard-events',
} as const;

export async function setupKafka() {
  kafka = new Kafka({
    clientId: config.kafkaClientId,
    brokers: config.kafkaBrokers,
    logLevel: config.nodeEnv === 'production' ? logLevel.WARN : logLevel.INFO,
    retry: {
      initialRetryTime: 100,
      retries: 8
    }
  });

  // Setup producer
  producer = kafka.producer({
    allowAutoTopicCreation: true,
    transactionTimeout: 30000
  });

  await producer.connect();
  console.log('✅ Kafka producer connected');

  // Create topics if they don't exist
  const admin = kafka.admin();
  await admin.connect();

  const existingTopics = await admin.listTopics();
  const topicsToCreate = Object.values(TOPICS).filter(t => !existingTopics.includes(t));

  if (topicsToCreate.length > 0) {
    await admin.createTopics({
      topics: topicsToCreate.map(topic => ({
        topic,
        numPartitions: 3,
        replicationFactor: 1
      }))
    });
    console.log(`✅ Created Kafka topics: ${topicsToCreate.join(', ')}`);
  }

  await admin.disconnect();

  return { kafka, producer };
}

export function getProducer() {
  if (!producer) {
    throw new Error('Kafka not initialized. Call setupKafka() first.');
  }
  return producer;
}

export function getKafka() {
  if (!kafka) {
    throw new Error('Kafka not initialized. Call setupKafka() first.');
  }
  return kafka;
}

// Helper to send GPS telemetry
export async function sendGpsPings(userId: string, pings: Array<{
  timestamp: string;
  lat: number;
  lng: number;
  speed_kmh: number;
  heading: number;
  accuracy_m: number;
}>) {
  await producer.send({
    topic: TOPICS.GPS_RAW,
    messages: pings.map(ping => ({
      key: userId,
      value: JSON.stringify({ userId, ...ping }),
      timestamp: new Date(ping.timestamp).getTime().toString()
    }))
  });
}

export { kafka, producer, consumer };
