// Supabase Edge Function untuk AI Chatbot myITS Synergy
// Context-Aware Chatbot menggunakan Google Gemini API

/// <reference path="../types.d.ts" />

// @ts-ignore: Deno imports
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
// @ts-ignore: Deno imports
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

// ===================================
// TYPES & INTERFACES
// ===================================

interface ChatRequest {
  message: string;
  include_context?: boolean; // Default: true
  conversation_history?: ChatMessage[];
}

interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
}

interface UserContext {
  profile?: {
    full_name: string;
    npm: string;
    major: string;
    intake_year: number;
  };
  upcoming_schedules?: Array<{
    course_name: string;
    schedule_day: string;
    start_time: string;
    end_time: string;
  }>;
  upcoming_tasks?: Array<{
    title: string;
    due_date: string;
    priority: string;
  }>;
  active_organizations?: Array<{
    organization_name: string;
    role: string;
  }>;
  recent_competitions?: Array<{
    competition_name: string;
    status: string;
  }>;
  projects_count?: number;
  current_semester?: string;
}

// ===================================
// CONTEXT RETRIEVAL FUNCTIONS
// ===================================

/**
 * Retrieve comprehensive user context from database
 */
async function getUserContext(userId: string, supabase: any): Promise<UserContext> {
  const context: UserContext = {};

  try {
    // 1. Get user profile
    const { data: profile } = await supabase
      .from('user_profiles')
      .select('full_name, npm, major, intake_year')
      .eq('user_id', userId)
      .single();
    
    if (profile) {
      context.profile = profile;
      
      // Calculate current semester
      const currentYear = new Date().getFullYear();
      const currentMonth = new Date().getMonth() + 1;
      const intakeYear = profile.intake_year || currentYear;
      const yearDiff = currentYear - intakeYear;
      const semester = (currentMonth >= 8) ? (yearDiff * 2 + 1) : (yearDiff * 2);
      context.current_semester = `Semester ${semester}`;
    }

    // 2. Get upcoming schedules (next 7 days)
    const today = new Date().toISOString().split('T')[0];
    const nextWeek = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    
    const { data: schedules } = await supabase
      .from('course_schedules')
      .select('course_name, schedule_day, start_time, end_time')
      .eq('user_id', userId)
      .order('schedule_day', { ascending: true })
      .limit(10);
    
    if (schedules && schedules.length > 0) {
      context.upcoming_schedules = schedules;
    }

    // 3. Get upcoming tasks (next 14 days, incomplete)
    const { data: tasks } = await supabase
      .from('user_tasks')
      .select('title, due_date, priority')
      .eq('user_id', userId)
      .eq('is_completed', false)
      .gte('due_date', today)
      .order('due_date', { ascending: true })
      .limit(10);
    
    if (tasks && tasks.length > 0) {
      context.upcoming_tasks = tasks;
    }

    // 4. Get active organizations
    const { data: organizations } = await supabase
      .from('user_organizations')
      .select('organization_name, role')
      .eq('user_id', userId)
      .eq('is_active', true)
      .limit(5);
    
    if (organizations && organizations.length > 0) {
      context.active_organizations = organizations;
    }

    // 5. Get recent competitions (last 6 months or upcoming)
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    
    const { data: competitions } = await supabase
      .from('user_competitions')
      .select('competition_name, status')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(5);
    
    if (competitions && competitions.length > 0) {
      context.recent_competitions = competitions;
    }

    // 6. Get projects count
    const { count: projectsCount } = await supabase
      .from('user_projects')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId);
    
    context.projects_count = projectsCount || 0;

  } catch (error) {
    console.error('Error retrieving user context:', error);
  }

  return context;
}

/**
 * Build system prompt with user context
 */
function buildSystemPrompt(userContext: UserContext): string {
  let prompt = `Kamu adalah asisten AI untuk aplikasi myITS Synergy, aplikasi manajemen akademik dan organisasi mahasiswa ITS (Institut Teknologi Sepuluh Nopember) Surabaya.

📋 IDENTITAS & KARAKTER:
- Nama: Synergy AI Assistant
- Personality: Friendly, supportive, sedikit santai tapi tetap profesional
- Bahasa: Bahasa Indonesia yang natural (boleh campur sedikit bahasa gaul mahasiswa)
- Tone: Seperti kakak tingkat yang helpful dan care

🎯 TUGASMU:
1. Membantu mahasiswa mengelola waktu antara kuliah, organisasi, kompetisi, dan project
2. Memberikan saran yang realistis dan actionable
3. Menganalisis data mereka untuk memberikan insight yang berguna
4. Menjadi decision-making partner (bukan hanya motivator)
5. Mengingatkan tentang deadline dan workload

⚠️ ATURAN PENTING:
- Jangan berpura-pura tahu informasi yang tidak ada di context
- Jika diminta data spesifik yang tidak tersedia, katakan dengan jujur
- Berikan jawaban yang konkret dan spesifik, bukan cuma generik
- Fokus pada produktivitas dan work-life balance
- Hindari jargon yang terlalu teknis kecuali diminta
- Gunakan emoji secukupnya untuk friendly vibes

`;

  // Add user-specific context
  if (userContext.profile) {
    prompt += `\n📝 PROFIL MAHASISWA:\n`;
    prompt += `- Nama: ${userContext.profile.full_name}\n`;
    prompt += `- NPM: ${userContext.profile.npm}\n`;
    prompt += `- Jurusan: ${userContext.profile.major}\n`;
    prompt += `- Angkatan: ${userContext.profile.intake_year}\n`;
    if (userContext.current_semester) {
      prompt += `- ${userContext.current_semester}\n`;
    }
  }

  if (userContext.upcoming_schedules && userContext.upcoming_schedules.length > 0) {
    prompt += `\n📚 JADWAL KULIAH TERDEKAT:\n`;
    userContext.upcoming_schedules.forEach(schedule => {
      prompt += `- ${schedule.course_name} (${schedule.schedule_day}, ${schedule.start_time}-${schedule.end_time})\n`;
    });
  }

  if (userContext.upcoming_tasks && userContext.upcoming_tasks.length > 0) {
    prompt += `\n✅ TUGAS/DEADLINE TERDEKAT:\n`;
    userContext.upcoming_tasks.forEach(task => {
      prompt += `- ${task.title} (Due: ${task.due_date}, Priority: ${task.priority})\n`;
    });
  }

  if (userContext.active_organizations && userContext.active_organizations.length > 0) {
    prompt += `\n🏢 ORGANISASI AKTIF:\n`;
    userContext.active_organizations.forEach(org => {
      prompt += `- ${org.organization_name} (${org.role})\n`;
    });
  }

  if (userContext.recent_competitions && userContext.recent_competitions.length > 0) {
    prompt += `\n🏆 KOMPETISI/LOMBA TERBARU:\n`;
    userContext.recent_competitions.forEach(comp => {
      prompt += `- ${comp.competition_name} (${comp.status})\n`;
    });
  }

  if (userContext.projects_count !== undefined) {
    prompt += `\n💼 JUMLAH PROJECT: ${userContext.projects_count}\n`;
  }

  prompt += `\n---\n`;
  prompt += `Gunakan informasi di atas untuk memberikan respon yang RELEVAN dan PERSONAL. Jika mahasiswa bertanya tentang jadwalnya, analisis dari data di atas. Jika bertanya keputusan, pertimbangkan workload mereka.\n`;

  return prompt;
}

/**
 * Call Gemini API with streaming support
 */
async function callGeminiAPI(
  systemPrompt: string,
  conversationHistory: ChatMessage[],
  userMessage: string
): Promise<string> {
  const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
  
  if (!geminiApiKey) {
    throw new Error('GEMINI_API_KEY not configured. Please set it in Supabase Edge Function secrets.');
  }

  // Build conversation for Gemini
  const fullPrompt = `${systemPrompt}\n\n=== PERCAKAPAN ===\n`;
  
  // Add conversation history
  let conversationText = fullPrompt;
  conversationHistory.forEach(msg => {
    conversationText += `${msg.role === 'user' ? '👤 User' : '🤖 Assistant'}: ${msg.content}\n\n`;
  });
  
  // Add current user message
  conversationText += `👤 User: ${userMessage}\n\n🤖 Assistant: `;

  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${geminiApiKey}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: [{
            parts: [{
              text: conversationText
            }]
          }],
          generationConfig: {
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 2048,
          },
          safetySettings: [
            {
              category: "HARM_CATEGORY_HARASSMENT",
              threshold: "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              category: "HARM_CATEGORY_HATE_SPEECH",
              threshold: "BLOCK_MEDIUM_AND_ABOVE"
            }
          ]
        }),
      }
    );

    if (!response.ok) {
      const errorData = await response.json();
      console.error('Gemini API error:', errorData);
      throw new Error(`Gemini API error: ${response.status}`);
    }

    const data = await response.json();
    
    if (!data.candidates || data.candidates.length === 0) {
      throw new Error('No response from Gemini API');
    }
    
    const aiResponse = data.candidates[0].content.parts[0].text.trim();
    return aiResponse;

  } catch (error) {
    console.error('Error calling Gemini API:', error);
    throw error;
  }
}

/**
 * Save chat message to database
 */
async function saveChatMessage(
  supabase: any,
  userId: string,
  message: string,
  isFromUser: boolean,
  userContext?: UserContext
) {
  try {
    await supabase
      .from('chat_messages')
      .insert({
        user_id: userId,
        message: message,
        is_from_user: isFromUser,
        user_context: userContext || null
      });
  } catch (error) {
    console.error('Error saving chat message:', error);
    // Non-blocking error - continue even if save fails
  }
}

// ===================================
// MAIN HANDLER
// ===================================

serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  console.log('Received request at /gemini-chat', req);

  try {
    // Parse request
    const requestBody: ChatRequest = await req.json();
    const { message, include_context = true, conversation_history = [] } = requestBody;

    if (!message || message.trim().length === 0) {
      console.log('Invalid request: message is required');
      return new Response(
        JSON.stringify({ 
          error: 'Message is required',
          success: false 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get user ID from request (optional for testing without context)
    const authHeader = req.headers.get('Authorization');
    let userId: string | null = null;
    
    // If include_context is true, authentication is required
    if (include_context) {
      if (!authHeader) {
        console.log('Authentication required but no Authorization header provided');
        return new Response(
          JSON.stringify({ 
            error: 'Authentication required when include_context is true',
            success: false 
          }),
          { 
            status: 401, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        );
      }

      const token = authHeader.replace('Bearer ', '');
      const { data: { user }, error: authError } = await supabase.auth.getUser(token);

      if (authError || !user) {
        console.log('Authentication failed:', authError?.message);
        return new Response(
          JSON.stringify({ 
            error: 'Invalid authentication',
            success: false 
          }),
          { 
            status: 401, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        );
      }
      
      userId = user.id;
    } else {
      // For testing without context, try to get user if auth header exists
      // but don't fail if token is invalid
      if (authHeader) {
        try {
          const token = authHeader.replace('Bearer ', '');
          const { data: { user }, error: authError } = await supabase.auth.getUser(token);
          if (user && !authError) {
            userId = user.id;
            console.log('Optional auth successful, user ID:', userId);
          } else {
            console.log('Optional auth failed, continuing without user context:', authError?.message);
          }
        } catch (error) {
          console.log('Optional auth error (ignored):', error);
          // Ignore auth errors when context is not required
        }
      }
    }

    // Retrieve user context
    let userContext: UserContext = {};
    if (include_context && userId) {
      console.log('Retrieving user context...');
      userContext = await getUserContext(userId, supabase);
      console.log('User context retrieved:', JSON.stringify(userContext, null, 2));
    }

    // Build system prompt
    const systemPrompt = buildSystemPrompt(userContext);

    // Save user message to database (only if authenticated)
    if (userId) {
      await saveChatMessage(supabase, userId, message, true, userContext);
    }

    // Call Gemini API
    console.log('Calling Gemini API...');
    const aiResponse = await callGeminiAPI(systemPrompt, conversation_history, message);
    console.log('AI Response received');

    // Save AI response to database (only if authenticated)
    if (userId) {
      await saveChatMessage(supabase, userId, aiResponse, false);
    }

    // Return response
    return new Response(
      JSON.stringify({
        success: true,
        response: aiResponse,
        context_used: include_context,
        timestamp: new Date().toISOString()
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    console.error('Edge Function error:', error);
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred',
        timestamp: new Date().toISOString()
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});
