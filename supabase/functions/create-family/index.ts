import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// 🎯 Handle requests
serve(async (req) => {
  // ✅ Handle CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Authorization, Content-Type, x-client-info, apikey",
      },
    });
  }

  // ✅ Init Supabase client
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
    const { family_name, role, actors, pin } = await req.json();

    // ✅ Basic input validation
    if (!family_name || !role || !Array.isArray(actors)) {
      return jsonResponse({ error: "Missing family_name, role, or actors" }, 400);
    }

    // ✅ Get authenticated user
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const now = new Date();

    // ✅ Validate & enrich actors
    const enrichedActors = [];
    for (let i = 0; i < actors.length; i++) {
      const actor = actors[i];
      if (!actor.name || !actor.type) {
        return jsonResponse(
          { error: `Actor at index ${i} is missing required fields: name or type` },
          400
        );
      }

      enrichedActors.push({
        name: actor.name,
        type: actor.type,
        coins_start_month: calculateCoinsForRestOfMonth(now),
      });
    }

    const totalCoins = enrichedActors.reduce(
      (sum, actor) => sum + actor.coins_start_month,
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
        pin,
      })
      .select()
      .single();

    if (familyError) {
      console.error("❌ Family insert error:", familyError.message);
      return jsonResponse({ error: familyError.message }, 500);
    }

    // ✅ Insert actors
    const actorRecords = enrichedActors.map(actor => ({
      ...actor,
      family_id: family.id,
    }));

    const { error: actorError } = await supabase
      .from("actors")
      .insert(actorRecords);

    if (actorError) {
      console.error("❌ Actor insert error:", actorError.message);
      return jsonResponse({ error: actorError.message }, 500);
    }

    // ✅ Insert or update user
    const { error: userError } = await supabase.from("users").upsert({
      id: user.id,
      email: user.email,
      full_name: user.user_metadata?.full_name || "Unknown",
      role,
      family_id: family.id,
      coin_balance: 0,
    });

    if (userError) {
      console.error("❌ User insert error:", userError.message);
      return jsonResponse({ error: userError.message }, 500);
    }

    return jsonResponse({ success: true, family_id: family.id });
  } catch (err) {
    console.error("❌ Unexpected error:", err);
    return jsonResponse({ error: "Invalid or missing JSON body" }, 400);
  }
});

// ✅ JSON response helper
function jsonResponse(data: any, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}

// ✅ Compute coins from now to end of month
function calculateCoinsForRestOfMonth(fromDate: Date): number {
  const matrix = getCareCoinMatrix();
  let total = 0;
  const current = new Date(fromDate);
  current.setMinutes(0, 0, 0);
  current.setHours(current.getHours() + 1);

  const endOfMonth = new Date(current.getFullYear(), current.getMonth() + 1, 1);

  while (current < endOfMonth) {
    const dow = current.getDay();
    const hour = current.getHours();
    total += matrix[dow][hour] ?? 0;
    current.setHours(current.getHours() + 1);
  }

  return total;
}

// ✅ Full 7x24 coin matrix
function getCareCoinMatrix(): number[][] {
  return [
    [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 2, 2, 2, 2, 1, 1],
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1],
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1],
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1],
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1],
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 4, 4, 4],
    [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4],
  ];
}
