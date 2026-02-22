// Supabase Edge Function untuk Generate Motivational Quotes
// Menggunakan OpenAI API untuk menggenerate quotes yang kontekstual

/// <reference path="../types.d.ts" />

// @ts-ignore: Deno imports
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
// @ts-ignore: Deno imports
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

// Tipe data untuk quote
interface MotivationalQuote {
  quote_text: string;
  theme: string;
  relevance_context: string;
}

// Tipe data untuk request body
interface RequestBody {
  context?: string;
  count?: number;
  theme?: string;
  replace_existing?: boolean;
}

// Fungsi untuk detect konteks berdasarkan tanggal
function detectContext(): { context: string; theme: string } {
  const now = new Date();
  const month = now.getMonth() + 1; // 1-12
  const day = now.getDate();

  // Detect semester
  const semester = (month >= 8 && month <= 12) || month === 1 ? 'Ganjil' : 'Genap';
  const year = month === 1 ? now.getFullYear() - 1 : now.getFullYear();

  // Detect periode akademik
  if (month === 9 || month === 2 || month === 3) {
    return {
      context: `Awal Semester ${semester} ${year}/${year + 1}`,
      theme: 'awal-semester',
    };
  }

  if ((month === 10 || month === 11) || (month === 4 || month === 5)) {
    return {
      context: `Pertengahan Semester ${semester} - Persiapan UTS ${year}/${year + 1}`,
      theme: 'UTS',
    };
  }

  if (month === 12 || month === 6) {
    return {
      context: `Akhir Semester ${semester} - Persiapan UAS ${year}/${year + 1}`,
      theme: 'UAS',
    };
  }

  if (month === 1 || month === 7 || month === 8) {
    return {
      context: `Libur Semester - Waktu Pengembangan Diri ${year}`,
      theme: 'libur',
    };
  }

  // Weather context untuk Surabaya
  if (month >= 11 || month <= 3) {
    return {
      context: `Musim Hujan di Surabaya - Semester ${semester} ${year}/${year + 1}`,
      theme: 'musim-hujan',
    };
  }

  return {
    context: `Semester ${semester} ${year}/${year + 1}`,
    theme: 'general',
  };
}

// Fungsi untuk generate quotes menggunakan Google Gemini (GRATIS!)
async function generateQuotes(
  context: string,
  theme: string,
  count: number,
): Promise<MotivationalQuote[]> {
  const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
  
  if (!geminiApiKey) {
    throw new Error('GEMINI_API_KEY not found. Get FREE API key at https://aistudio.google.com/app/apikey');
  }

  const prompt = `Kamu adalah motivator mahasiswa Indonesia, khususnya mahasiswa ITS (Institut Teknologi Sepuluh Nopember) Surabaya. 

Tugasmu adalah membuat ${count} kata-kata motivasi yang:
- Relevan dengan kehidupan mahasiswa Indonesia
- Mempertimbangkan konteks akademik (UTS, UAS, semester, dll)
- Mempertimbangkan budaya Indonesia dan bahasa yang familiar
- Mendorong keseimbangan antara akademik, organisasi, kompetisi, dan pengembangan diri
- Fokus pada produktivitas, konsistensi, dan karakter
- Tidak terlalu formal, friendly seperti teman sebaya
- Panjang maksimal 150 karakter agar mudah dibaca
- Menghindari klise yang terlalu umum

Konteks saat ini: ${context}
Theme: ${theme}

${theme === 'tugas-akhir' ? `
🎓 SPECIAL THEME: MOTIVASI TUGAS AKHIR (TA) 🎓
Quote khusus untuk mahasiswa tingkat akhir (semester 7-8) yang sedang mengerjakan Tugas Akhir (Skripsi/Thesis).

Fokus motivasi:
- Semangat menyelesaikan TA di tengah tantangan
- Konsistensi dalam progress TA (sedikit-sedikit lama-lama jadi bukit)
- Mengatasi rasa jenuh dan writer's block
- Percaya diri menghadapi bimbingan dan revisi
- Mengingatkan bahwa finish line sudah dekat
- Kebanggaan akan pencapaian besar yang sedang dikerjakan
- Work-life balance selama mengerjakan TA

Gunakan tone yang empati, supportive, dan realistic (acknowledge bahwa TA itu challenging tapi achievable).
` : ''}

Generate ${count} kata-kata motivasi yang unik dan relevan untuk mahasiswa dalam konteks "${context}". 

Setiap quote harus:
1. Original dan tidak klise
2. Spesifik untuk situasi mahasiswa saat ini
3. Menginspirasi action, bukan hanya perasaan
4. Menggunakan bahasa Indonesia yang natural

Format response sebagai JSON array (HANYA JSON, tanpa text lain):
[
  {
    "quote_text": "kata motivasi disini",
    "theme": "${theme}",
    "relevance_context": "kapan atau untuk siapa quote ini paling relevan"
  }
]`;

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
              text: prompt
            }]
          }],
          generationConfig: {
            temperature: 0.9,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 2048,
          },
        }),
      }
    );

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(`Gemini API error: ${JSON.stringify(errorData)}`);
    }

    const data = await response.json();
    
    if (!data.candidates || data.candidates.length === 0) {
      throw new Error('No response from Gemini API');
    }
    
    const content = data.candidates[0].content.parts[0].text.trim();
    
    // Parse JSON response - remove markdown code blocks if present
    let jsonContent = content;
    if (content.startsWith('```json')) {
      jsonContent = content.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    } else if (content.startsWith('```')) {
      jsonContent = content.replace(/```\n?/g, '');
    }
    
    const quotes: MotivationalQuote[] = JSON.parse(jsonContent);
    
    return quotes;
  } catch (error) {
    console.error('Error generating quotes with Gemini:', error);
    throw error;
  }
}

// Main handler
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

  try {
    // Parse request body
    const body: RequestBody = await req.json().catch(() => ({}));
    const quotesCount = body.count || 10;
    const replaceExisting = body.replace_existing || false;

    // Detect atau gunakan context yang diberikan
    const detected = detectContext();
    const context = body.context || detected.context;
    const theme = body.theme || detected.theme;

    console.log(`Generating ${quotesCount} quotes for context: ${context}, theme: ${theme}`);

    // Generate quotes menggunakan OpenAI
    const generatedQuotes = await generateQuotes(context, theme, quotesCount);

    // Simpan ke Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Jika replace_existing = true, nonaktifkan quotes lama dengan theme yang sama
    if (replaceExisting) {
      const { error: updateError } = await supabase
        .from('motivational_quotes')
        .update({ is_active: false })
        .eq('theme', theme);

      if (updateError) {
        console.error('Error deactivating old quotes:', updateError);
      } else {
        console.log(`Deactivated old quotes with theme: ${theme}`);
      }
    }

    // Insert quotes baru
    const { data: insertedQuotes, error: insertError } = await supabase
      .from('motivational_quotes')
      .insert(generatedQuotes)
      .select();

    if (insertError) {
      throw new Error(`Failed to insert quotes: ${insertError.message}`);
    }

    console.log(`Successfully inserted ${insertedQuotes?.length || 0} quotes`);

    // Response
    return new Response(
      JSON.stringify({
        success: true,
        generated_count: generatedQuotes.length,
        inserted_count: insertedQuotes?.length || 0,
        context: context,
        theme: theme,
        quotes_preview: insertedQuotes?.slice(0, 3).map(q => q.quote_text),
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    );
  } catch (error) {
    console.error('Error in generate-motivational-quotes function:', error);
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    );
  }
});
