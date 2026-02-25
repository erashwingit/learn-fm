/**
 * Supabase Edge Function: ai-chat
 *
 * Proxies Claude AI requests server-side so the Anthropic API key
 * is NEVER exposed in the Flutter client bundle.
 *
 * Deploy:
 *   supabase functions deploy ai-chat --no-verify-jwt
 *
 * Required Edge Function secrets (set via Supabase dashboard or CLI):
 *   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ─── Types ────────────────────────────────────────────────────────────────────
interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
}

interface AiChatRequest {
  question: string;
  conversationHistory?: ChatMessage[];
  domainContext?: string;
  language?: 'en' | 'hi';
}

interface AiChatResponse {
  answer: string;
  sources?: string[];
  tokensUsed?: number;
}

// ─── Constants ────────────────────────────────────────────────────────────────
const ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages';
const MAX_TOKENS = 1024;
const CLAUDE_MODEL = 'claude-3-5-sonnet-20241022';
const RATE_LIMIT_PER_DAY = 50;
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// ─── Helpers ──────────────────────────────────────────────────────────────────
function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}

function errorResponse(message: string, status = 400): Response {
  return jsonResponse({ error: message }, status);
}

// ─── Rate Limiting ────────────────────────────────────────────────────────────
async function checkRateLimit(
  supabase: ReturnType<typeof createClient>,
  userId: string,
): Promise<boolean> {
  const today = new Date().toISOString().split('T')[0];

  const { data, error } = await supabase
    .from('ai_usage_log')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .gte('created_at', `${today}T00:00:00.000Z`);

  if (error) {
    console.error('Rate limit check failed:', error.message);
    return true; // fail open — do not block user on DB error
  }

  return (data?.length ?? 0) < RATE_LIMIT_PER_DAY;
}

async function logUsage(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  tokensUsed: number,
): Promise<void> {
  await supabase.from('ai_usage_log').insert({
    user_id: userId,
    tokens_used: tokensUsed,
    created_at: new Date().toISOString(),
  });
}

// ─── Vector Search ────────────────────────────────────────────────────────────
async function getRelevantContext(
  supabase: ReturnType<typeof createClient>,
  question: string,
  domainContext?: string,
): Promise<string> {
  try {
    // Generate embedding for the question via Supabase's pg_net + OpenAI
    // (or use Supabase's built-in vector similarity with a pre-computed embedding)
    const { data: chunks, error } = await supabase.rpc('match_documents', {
      query_text: question,
      domain_filter: domainContext ?? null,
      match_count: 5,
    });

    if (error || !chunks || chunks.length === 0) return '';

    return chunks
      .map((c: { content: string; title: string }) => `[${c.title}]\n${c.content}`)
      .join('\n\n---\n\n');
  } catch {
    return ''; // non-fatal — Claude will answer from general knowledge
  }
}

// ─── System Prompt ────────────────────────────────────────────────────────────
function buildSystemPrompt(language: string, context: string): string {
  const langInstruction =
    language === 'hi'
      ? 'Always respond in Hindi unless the user writes in English.'
      : 'Always respond in English.';

  return `You are an expert Facility Management (FM) training assistant for the Learn FM platform in India.
Your role is to help frontline FM workers learn skills across 14 domains: Technical Services, Housekeeping,
Security Management, Fire & Safety, Facade Cleaning, Pest Control, Helpdesk, Accounts, Budgeting,
Building Compliances, Labour Compliances, Vendor Management, Store Management, and Procurement.

${langInstruction}

Guidelines:
- Be practical and use simple, easy-to-understand language suited for frontline workers
- Reference Indian FM standards, regulations, and best practices where applicable
- Provide step-by-step explanations for procedures
- When relevant, cite safety considerations
- Keep answers concise but complete

${context ? `Relevant knowledge base context:\n${context}` : ''}`.trim();
}

// ─── Main Handler ─────────────────────────────────────────────────────────────
serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }

  if (req.method !== 'POST') {
    return errorResponse('Method not allowed', 405);
  }

  try {
    // ── 1. Authenticate the caller ───────────────────────────────────────────
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return errorResponse('Missing Authorization header', 401);

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const anthropicKey = Deno.env.get('ANTHROPIC_API_KEY')!;

    if (!anthropicKey) return errorResponse('AI service unavailable', 503);

    // Use service role client to bypass RLS for usage logging
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Verify JWT and extract user
    const jwt = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(jwt);

    if (authError || !user) return errorResponse('Unauthorized', 401);

    // ── 2. Rate limit check ──────────────────────────────────────────────────
    const withinLimit = await checkRateLimit(supabase, user.id);
    if (!withinLimit) {
      return errorResponse('Daily AI query limit reached (50/day). Try again tomorrow.', 429);
    }

    // ── 3. Parse request body ────────────────────────────────────────────────
    const body: AiChatRequest = await req.json();
    const { question, conversationHistory = [], domainContext, language = 'en' } = body;

    if (!question?.trim()) return errorResponse('Question is required', 400);

    // ── 4. Retrieve relevant context from vector store ───────────────────────
    const knowledgeContext = await getRelevantContext(supabase, question, domainContext);

    // ── 5. Build messages for Claude ─────────────────────────────────────────
    const systemPrompt = buildSystemPrompt(language, knowledgeContext);

    const messages: ChatMessage[] = [
      ...conversationHistory.slice(-10), // keep last 10 turns for context
      { role: 'user', content: question },
    ];

    // ── 6. Call Claude API (server-side — key never leaves Edge Function) ────
    const claudeResponse = await fetch(ANTHROPIC_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': anthropicKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: CLAUDE_MODEL,
        max_tokens: MAX_TOKENS,
        system: systemPrompt,
        messages,
      }),
    });

    if (!claudeResponse.ok) {
      const err = await claudeResponse.text();
      console.error('Claude API error:', claudeResponse.status, err);
      return errorResponse('AI service temporarily unavailable. Please try again.', 502);
    }

    const claudeData = await claudeResponse.json();
    const answer: string = claudeData.content?.[0]?.text ?? '';
    const tokensUsed: number = claudeData.usage?.input_tokens + claudeData.usage?.output_tokens ?? 0;

    // ── 7. Log usage for rate limiting ───────────────────────────────────────
    await logUsage(supabase, user.id, tokensUsed);

    // ── 8. Return response ───────────────────────────────────────────────────
    const response: AiChatResponse = {
      answer,
      tokensUsed,
      sources: knowledgeContext
        ? knowledgeContext
            .split('---')
            .map((s) => s.match(/\[(.+?)\]/)?.[1])
            .filter(Boolean) as string[]
        : [],
    };

    return jsonResponse(response);
  } catch (err) {
    console.error('Edge function error:', err);
    return errorResponse('Internal server error', 500);
  }
});
