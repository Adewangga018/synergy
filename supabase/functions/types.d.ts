// Type definitions for Deno Edge Functions
// This file helps VS Code understand Deno imports

declare module 'https://deno.land/std@0.177.0/http/server.ts' {
  export function serve(handler: (req: Request) => Response | Promise<Response>): void;
}

declare module 'https://esm.sh/@supabase/supabase-js@2.39.0' {
  export interface SupabaseClient {
    from(table: string): any;
    rpc(fn: string, params?: any): any;
  }
  
  export function createClient(url: string, key: string): SupabaseClient;
}

// Deno global namespace and APIs
declare global {
  const Deno: {
    env: {
      get(key: string): string | undefined;
    };
  };
}

export {};
