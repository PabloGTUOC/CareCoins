import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// 🎯 Handle requests
serve(async (req) => {
  // ✅ CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Authorization, Content-Type",
      },
    });
  }

  // ✅ Supabase client (with auth header from the request)
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    {
      global: {
        headers: { Authorization: req.headers.get("Authorization")! },
      },
    }
  );

  try {
    const { family_name, role, actors } = await req.json();

    if (!family_name || !role || !Array.isArray(actors)) {
      return jsonResponse({ error: "Missing family_name, role, or actors" }, 400);
    }

    // ✅ Get current authenticated user
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const now = new Date();
    const enrichedActors = actors.map((actor: any) => ({
      name: actor.name,
      type: actor.type,
      coins_start_month: calculateCoinsForRestOfMonth(now),
    }));

    const totalCoins = enrichedActors.reduce(
      (sum: number, actor: any) => sum + actor.coins_start_month,
      0
    );

    // ✅ Insert family
    const { data: family, error: familyError } = await supabase
      .from("families")
      .insert({
        name: family_name,
        coins_start_month: totalCoins,
        coins_pending: totalCoins,
        coins_paid: 0,
      })
      .select()
      .single();

    if (familyError) {
      return jsonResponse({ error: familyError.message }, 500);
    }

    // ✅ Insert actors
    const actorRecords = enrichedActors.map((actor: any) => ({
      name: actor.name,
      type: actor.type,
      coins_start_month: actor.coins_start_month,
      family_id: family.id,
    }));

    const { error: actorError } = await supabase
      .from("actors")
      .insert(actorRecords);

    if (actorError) {
      return jsonResponse({ error: actorError.message }, 500);
    }

    // ✅ Insert user
    const { error: userError } = await supabase.from("users").insert({
      id: user.id,
      email: user.email,
      full_name: user.user_metadata?.full_name || "Unknown",
      role,
      family_id: family.id,
      coin_balance: 0,
    });

    if (userError) {
      return jsonResponse({ error: userError.message }, 500);
    }

    return jsonResponse({ success: true, family_id: family.id });
  } catch (err) {
    return jsonResponse({ error: "Invalid or missing JSON body" }, 400);
  }
});

// ✅ Helper: Unified CORS JSON Response
function jsonResponse(data: any, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*", // 🌍 change to your domain in prod
    },
  });
}

// ✅ Helper: Calculate coins left in month based on your matrix
function calculateCoinsForRestOfMonth(fromDate: Date): number {
  const matrix = getCareCoinMatrix();
  let total = 0;
  const current = new Date(fromDate);
  current.setMinutes(0, 0, 0);
  current.setHours(current.getHours() + 1);

  const endOfMonth = new Date(current.getFullYear(), current.getMonth() + 1, 1);

  while (current < endOfMonth) {
    const dow = current.getDay(); // 0=Sun
    const hour = current.getHours();
    total += matrix[dow][hour] ?? 0;
    current.setHours(current.getHours() + 1);
  }

  return total;
}

// ✅ Your full matrix from spreadsheet
function getCareCoinMatrix(): number[][] {
  return [
    [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 2, 2, 2, 2, 1, 1], // Sunday
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1], // Monday
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1], // Tuesday
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1], // Wednesday
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1], // Thursday
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 4, 4, 4], // Friday
    [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4], // Saturday
  ];
}
