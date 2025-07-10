import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Authorization, x-client-info, Content-Type, apikey",
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
    const { title, type, actor, scheduled_at, ends_at } = await req.json();

    if (!title || !type || !scheduled_at || !ends_at) {
      return jsonResponse({ error: "Missing required fields" }, 400);
    }

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const { data: userProfile, error: profileError } = await supabase
      .from("users")
      .select("family_id")
      .eq("id", user.id)
      .maybeSingle();

    if (profileError || !userProfile?.family_id) {
      return jsonResponse({ error: "User has no associated family" }, 400);
    }

    const activity = {
      title,
      type,
      actor_id: type === "Caring of" ? actor : null,
      scheduled_at,
      ends_at,
      user_id: user.id,
      family_id: userProfile.family_id,
    };

    const { error: insertError } = await supabase
      .from("activities")
      .insert(activity);

    if (insertError) {
      console.error('Insert error:', insertError);
      console.error('Activity payload:', activity);
      return jsonResponse({ error: insertError.message }, 500);
    }

    return jsonResponse({ success: true });
  } catch (err) {
    console.error('Unhandled error:', err);
    return jsonResponse({ error: "Invalid request payload" }, 400);
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
