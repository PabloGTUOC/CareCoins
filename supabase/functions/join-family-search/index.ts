import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

serve(async (req) => {
  // ✅ Handle preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      status: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Authorization, Content-Type, x-client-info, apikey",
      },
    });
  }

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
    const { query } = await req.json();

    if (!query || typeof query !== "string") {
      return jsonResponse({ error: "Invalid query" }, 400);
    }

    const isUuid = /^[0-9a-fA-F-]{36}$/.test(query);
    let data, error;

    if (isUuid) {
      const result = await supabase
        .from("families")
        .select("*")
        .eq("id", query)
        .limit(1);
      data = result.data;
      error = result.error;
    } else {
      const result = await supabase
        .from("families")
        .select("*")
        .ilike("name", `%${query}%`)
        .limit(5);
      data = result.data;
      error = result.error;
    }

    if (error) {
      return jsonResponse({ error: error.message }, 500);
    }

    return jsonResponse({ families: data });
  } catch (err) {
    return jsonResponse({ error: "Invalid request body" }, 400);
  }
});

function jsonResponse(data: any, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
