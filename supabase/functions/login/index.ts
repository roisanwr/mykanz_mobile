// Supabase Edge Function: login
// Verifikasi email + bcrypt password dari public.users
// Return custom JWT dengan claim { sub: user_id }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as bcrypt from "https://deno.land/x/bcrypt@v0.4.1/mod.ts";
import { create, getNumericDate } from "https://deno.land/x/djwt@v3.0.2/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { email, password } = await req.json();

    if (!email || !password) {
      return new Response(
        JSON.stringify({ error: "Email dan password wajib diisi" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Gunakan service_role key untuk query public.users (bypass RLS)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Cari user berdasarkan email
    const { data: user, error: userError } = await supabase
      .from("users")
      .select("id, name, email, password_hash")
      .eq("email", email)
      .single();

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Email atau password salah" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!user.password_hash) {
      return new Response(
        JSON.stringify({ error: "Akun ini tidak mendukung login dengan password" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Verifikasi bcrypt password
    const isValid = await bcrypt.compare(password, user.password_hash);

    if (!isValid) {
      return new Response(
        JSON.stringify({ error: "Email atau password salah" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Buat JWT dengan claim yang kompatibel dengan Supabase RLS
    // JWT Secret harus sama dengan Supabase JWT Secret di project settings
    const jwtSecret = Deno.env.get("SUPABASE_JWT_SECRET")!;
    const key = await crypto.subtle.importKey(
      "raw",
      new TextEncoder().encode(jwtSecret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign", "verify"]
    );

    const payload = {
      // Standard JWT claims
      iss: Deno.env.get("SUPABASE_URL"),
      sub: user.id,                          // user_id — dipakai RLS: auth.uid()
      aud: "authenticated",
      exp: getNumericDate(60 * 60 * 24 * 7), // 7 hari
      iat: getNumericDate(0),
      // Supabase-specific claims
      role: "authenticated",
      // Custom claims untuk app
      user_metadata: {
        name: user.name,
        email: user.email,
      },
    };

    const accessToken = await create({ alg: "HS256", typ: "JWT" }, payload, key);

    return new Response(
      JSON.stringify({
        access_token: accessToken,
        token_type: "bearer",
        expires_in: 604800, // 7 hari dalam detik
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
        },
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );

  } catch (error) {
    console.error("Login error:", error);
    return new Response(
      JSON.stringify({ error: "Terjadi kesalahan server" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
