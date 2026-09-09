import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { amount, bookingId, receipt } = await req.json();

    const RAZORPAY_KEY = Deno.env.get("RAZORPAY_API_KEY");
    const RAZORPAY_SECRET = Deno.env.get("RAZORPAY_SECRET_KEY");

    if (!RAZORPAY_KEY || !RAZORPAY_SECRET) {
      throw new Error("Razorpay credentials are not configured");
    }

    const auth = btoa(`${RAZORPAY_KEY}:${RAZORPAY_SECRET}`);
    
    // Create Razorpay Order
    const rzpResponse = await fetch("https://api.razorpay.com/v1/orders", {
      method: "POST",
      headers: {
        Authorization: `Basic ${auth}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        amount: amount * 100, // Razorpay works in paise
        currency: "INR",
        receipt: receipt || `receipt_${bookingId}`,
      }),
    });

    const orderData = await rzpResponse.json();

    if (!rzpResponse.ok) {
      throw new Error(orderData.error?.description || "Failed to create order");
    }

    return new Response(JSON.stringify(orderData), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
