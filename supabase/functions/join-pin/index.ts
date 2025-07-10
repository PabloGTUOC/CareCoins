import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
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
    const { family_id, pin } = await req.json();

    if (!family_id || !pin) {
      return jsonResponse({ error: "Missing family_id or pin" }, 400);
    }

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const { data: family, error: familyError } = await supabase
      .from("families")
      .select("id, pin")
      .eq("id", family_id)
      .maybeSingle();

    if (familyError || !family) {
      return jsonResponse({ error: "Family not found" }, 404);
    }

    if (family.pin !== pin) {
      return jsonResponse({ error: "Incorrect PIN" }, 403);
    }

    const { error: updateError } = await supabase
      .from("users")
      .update({ family_id })
      .eq("id", user.id);

    if (updateError) {
      return jsonResponse({ error: updateError.message }, 500);
    }

    return jsonResponse({ success: true, family_id });
  } catch (err) {
    return jsonResponse({ error: "Invalid request" }, 400);
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
