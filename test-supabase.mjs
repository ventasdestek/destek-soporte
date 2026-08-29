// Script de diagnóstico: prueba la conexión real con Supabase
// Ejecutar con: node test-supabase.mjs
import { createClient } from '@supabase/supabase-js'
import { readFileSync } from 'node:fs'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))

function loadEnv(file) {
  const out = {}
  try {
    const content = readFileSync(resolve(__dirname, file), 'utf8')
    for (const raw of content.split(/\r?\n/)) {
      const line = raw.trim()
      if (!line || line.startsWith('#')) continue
      const idx = line.indexOf('=')
      if (idx === -1) continue
      const key = line.slice(0, idx).trim()
      let val = line.slice(idx + 1).trim()
      if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
        val = val.slice(1, -1)
      }
      out[key] = val
    }
  } catch (e) { console.error('No se pudo leer', file, e.message) }
  return out
}

const env = loadEnv('.env.local')
const url = env.NEXT_PUBLIC_SUPABASE_URL
const anonKey = env.NEXT_PUBLIC_SUPABASE_ANON_KEY || env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY
const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY

const log = (label, ok, extra = '') => {
  const icon = ok === true ? '\u2705' : ok === false ? '\u274C' : '\u2139\uFE0F '
  console.log(`${icon} ${label}${extra ? '  ' + extra : ''}`)
}

console.log('\n=== 1. Variables de entorno ===')
log('NEXT_PUBLIC_SUPABASE_URL', !!url, url || '')
log('ANON/PUBLISHABLE KEY', !!anonKey, anonKey ? `long=${anonKey.length}` : '')
log('SERVICE_ROLE KEY', !!serviceKey, serviceKey ? `long=${serviceKey.length}` : '')

if (!url || !serviceKey) { console.log('\nFaltan variables. Abortando.'); process.exit(1) }

try {
  const u = new URL(url)
  log('URL valida https://*.supabase.co', u.protocol === 'https:' && u.hostname.endsWith('.supabase.co'), `host=${u.hostname}`)
} catch (e) { log('URL invalida', false, e.message); process.exit(1) }

console.log('\n=== 2. HTTP al endpoint REST ===')
try {
  const r = await fetch(`${url}/rest/v1/`, { headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` } })
  log(`HTTP ${r.status} a /rest/v1/`, r.ok)
} catch (e) { log('Fallo de red', false, e.message) }

const supabase = createClient(url, serviceKey, { auth: { autoRefreshToken: false, persistSession: false } })

const candidatas = [
  'profiles','pedidos','services','servicios','categorias','clientes',
  'contactos','newsletter','cotizaciones','proyectos','facturas',
  'productos','tickets','usuarios','roles','sessions',
  'company_settings','site_settings','testimonios','portfolio',
  'posts','categories','tags','comments','orders','order_items',
  'services_categories','contact_messages','leads','faqs',
  'solicitudes','presupuestos','reparaciones','diagnosticos',
]

console.log('\n=== 3. Sondeo de tablas (service_role) ===')
const resultados = []
for (const t of candidatas) {
  const { error, count } = await supabase.from(t).select('*', { count: 'exact', head: true })
  if (error) resultados.push({ tabla: t, estado: 'NO', detalle: (error.code || error.message).slice(0, 40) })
  else resultados.push({ tabla: t, estado: 'OK', filas: count })
}
console.table(resultados)

const existentes = resultados.filter(r => r.estado === 'OK')
log(`Tablas accesibles: ${existentes.length}`, existentes.length > 0)

console.log('\n=== 4. Muestra de cada tabla ===')
for (const r of existentes) {
  const { data, error } = await supabase.from(r.tabla).select('*').limit(1)
  if (error) { console.log(`- ${r.tabla}: error al leer (${error.message})`); continue }
  if (!data || data.length === 0) { console.log(`- ${r.tabla}: vacia`); continue }
  const fila = data[0]
  const cols = Object.keys(fila)
  console.log(`- ${r.tabla}: ${r.filas} fila(s), columnas: ${cols.join(', ')}`)
}

console.log('\n=== 5. Auth (anon) ===')
const anon = createClient(url, anonKey, { auth: { persistSession: false } })
const { data: sess, error: sessErr } = await anon.auth.getSession()
if (sessErr) log('getSession anon', false, sessErr.message)
else log('anon responde', true, `session=${sess.session ? 'activa' : 'null'}`)

console.log('\n=== 6. Vercel ===')
log('VERCEL_OIDC_TOKEN presente', !!env.VERCEL_OIDC_TOKEN)

console.log('\nDiagnostico finalizado.\n')
