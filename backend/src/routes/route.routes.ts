import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { z } from 'zod';
import { authenticate } from '../middleware/auth.middleware.js';
import { getDb } from '../config/database.js';
import { config } from '../config/index.js';

const routeRequestSchema = z.object({
  origin: z.object({
    lat: z.number().min(-90).max(90),
    lng: z.number().min(-180).max(180)
  }),
  destination: z.object({
    lat: z.number().min(-90).max(90),
    lng: z.number().min(-180).max(180)
  }),
  waypoints: z.array(z.object({
    lat: z.number().min(-90).max(90),
    lng: z.number().min(-180).max(180)
  })).optional(),
  truck_profile_id: z.string().uuid().optional(),
  avoid: z.array(z.enum(['tolls', 'ferries', 'highways'])).optional(),
  exclude_countries: z.array(z.string().length(2)).optional(),
  departure_time: z.string().datetime().optional()
});

export default async function routeRoutes(app: FastifyInstance) {
  // Calculate truck route via Valhalla
  app.post('/', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { userId } = request.user as { userId: string };
      const body = routeRequestSchema.parse(request.body);
      const sql = getDb();

      // Get truck profile
      let truckProfile = null;
      if (body.truck_profile_id) {
        [truckProfile] = await sql`
          SELECT * FROM truck_profiles
          WHERE id = ${body.truck_profile_id} AND user_id = ${userId}
        `;
      } else {
        // Get default truck profile
        [truckProfile] = await sql`
          SELECT * FROM truck_profiles
          WHERE user_id = ${userId} AND is_default = true
        `;
      }

      // Build Valhalla request
      const locations = [
        { lat: body.origin.lat, lon: body.origin.lng },
        ...(body.waypoints?.map(w => ({ lat: w.lat, lon: w.lng })) || []),
        { lat: body.destination.lat, lon: body.destination.lng }
      ];

      // Build costing options for truck
      const costingOptions: Record<string, unknown> = {
        truck: {
          height: truckProfile ? truckProfile.height_cm / 100 : 4.0,
          width: truckProfile ? truckProfile.width_cm / 100 : 2.6,
          length: truckProfile ? truckProfile.length_cm / 100 : 16.5,
          weight: truckProfile ? truckProfile.weight_kg / 1000 : 40,
          axle_load: truckProfile ? truckProfile.axle_weight_kg / 1000 : 10,
          hazmat: truckProfile?.hazmat_class ? true : false,
          use_tolls: body.avoid?.includes('tolls') ? 0 : 1,
          use_ferry: body.avoid?.includes('ferries') ? 0 : 1,
          use_highways: body.avoid?.includes('highways') ? 0.5 : 1
        }
      };

      const valhallaRequest = {
        locations,
        costing: 'truck',
        costing_options: costingOptions,
        directions_options: {
          units: 'kilometers',
          language: 'en'
        }
      };

      // Call Valhalla
      try {
        const response = await fetch(`${config.valhallaUrl}/route`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(valhallaRequest)
        });

        if (!response.ok) {
          const error = await response.text();
          app.log.error(`Valhalla error: ${error}`);
          return reply.status(502).send({ error: 'Routing service error' });
        }

        const result = await response.json();

        // Transform Valhalla response
        const trip = result.trip;
        const leg = trip.legs[0];

        return reply.send({
          route: {
            type: 'Feature',
            geometry: {
              type: 'LineString',
              coordinates: decodePolyline(leg.shape)
            },
            properties: {
              distance_km: trip.summary.length,
              duration_min: Math.round(trip.summary.time / 60)
            }
          },
          distance_km: trip.summary.length,
          duration_min: Math.round(trip.summary.time / 60),
          maneuvers: leg.maneuvers?.map((m: Record<string, unknown>) => ({
            instruction: m.instruction,
            distance_km: m.length,
            type: m.type
          })),
          warnings: [] // TODO: Add restriction warnings based on confidence
        });
      } catch (error) {
        app.log.error('Valhalla request failed:', error);
        return reply.status(502).send({ error: 'Routing service unavailable' });
      }
    }
  });
}

// Decode Valhalla's encoded polyline
function decodePolyline(encoded: string, precision = 6): number[][] {
  const coordinates: number[][] = [];
  let index = 0;
  let lat = 0;
  let lng = 0;

  while (index < encoded.length) {
    let shift = 0;
    let result = 0;
    let byte: number;

    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    const dlat = result & 1 ? ~(result >> 1) : result >> 1;
    lat += dlat;

    shift = 0;
    result = 0;

    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    const dlng = result & 1 ? ~(result >> 1) : result >> 1;
    lng += dlng;

    coordinates.push([lng / Math.pow(10, precision), lat / Math.pow(10, precision)]);
  }

  return coordinates;
}
