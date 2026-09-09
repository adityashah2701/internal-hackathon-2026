import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";
import { createHmac } from "node:crypto";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, booking_id } = await req.json();

    const RAZORPAY_SECRET = Deno.env.get("RAZORPAY_SECRET_KEY");
    if (!RAZORPAY_SECRET) {
      throw new Error("Razorpay credentials are not configured");
    }

    // Verify signature
    const hmac = createHmac("sha256", RAZORPAY_SECRET);
    hmac.update(`${razorpay_order_id}|${razorpay_payment_id}`);
    const generatedSignature = hmac.digest("hex");

    if (generatedSignature !== razorpay_signature) {
      throw new Error("Invalid payment signature");
    }

    // Init Supabase admin to bypass RLS for updating booking status safely
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // 1. Update Booking Status
    const { data: booking, error: updateError } = await supabaseAdmin
      .from("bookings")
      .update({ status: "payment_confirmed" })
      .eq("id", booking_id)
      .select()
      .single();

    if (updateError) throw updateError;

    // 2. Generate Invoice (optional, can be done via trigger, doing here explicitly)
    const { error: invoiceError } = await supabaseAdmin
      .from("invoices")
      .insert({
        booking_id: booking_id,
        customer_id: booking.customer_id,
        worker_id: booking.worker_id,
        amount: booking.total_amount,
        status: "paid",
        payment_id: razorpay_payment_id
      });
      
    if (invoiceError) {
        console.error("Failed to generate invoice", invoiceError);
        // Continue anyway since payment succeeded
    }

    return new Response(JSON.stringify({ success: true }), {
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
