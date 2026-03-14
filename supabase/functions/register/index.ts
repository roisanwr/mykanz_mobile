// Supabase Edge Function: register
// Buat user baru di public.users dengan bcrypt password hash

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as bcrypt from "https://deno.land/x/bcrypt@v0.4.1/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { name, email, password } = await req.json();

    if (!name || !email || !password) {
      return new Response(
        JSON.stringify({ error: "Nama, email, dan password wajib diisi" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (password.length < 8) {
      return new Response(
        JSON.stringify({ error: "Password minimal 8 karakter" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Cek apakah email sudah terdaftar
    const { data: existing } = await supabase
      .from("users")
      .select("id")
      .eq("email", email)
      .single();

    if (existing) {
      return new Response(
        JSON.stringify({ error: "Email sudah terdaftar" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Hash password dengan bcrypt (salt rounds: 10, sama dengan web)
    const passwordHash = await bcrypt.hash(password);

    // Insert user baru
    const { data: newUser, error: insertError } = await supabase
      .from("users")
      .insert({ name, email, password_hash: passwordHash })
      .select("id, name, email")
      .single();

    if (insertError || !newUser) {
      throw insertError;
    }

    return new Response(
      JSON.stringify({
        message: "Registrasi berhasil",
        user: { id: newUser.id, name: newUser.name, email: newUser.email },
      }),
      {
        status: 201,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );

  } catch (error) {
    console.error("Register error:", error);
    return new Response(
      JSON.stringify({ error: "Terjadi kesalahan server" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
