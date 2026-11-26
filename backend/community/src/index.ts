/**
 * API de comunidad de NuvTune (fase 1): cuentas y amistades.
 *
 * Solo guarda identidad y relaciones. El audio nunca pasa por aqui: en fases
 * posteriores viajara directo de telefono a telefono por WebRTC y este Worker
 * hara de señalizacion.
 */

export interface Env {
  DB: D1Database;
}

class HttpError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
  }
}

const USERNAME = /^[a-z0-9_]{3,20}$/;
// Workers limita PBKDF2 a 100000 iteraciones.
const PBKDF2_ITERATIONS = 100_000;

const json = (body: unknown, status = 200): Response =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });

const toHex = (bytes: ArrayBuffer | Uint8Array): string =>
  [...new Uint8Array(bytes)].map((b) => b.toString(16).padStart(2, '0')).join('');

const fromHex = (hex: string): Uint8Array =>
  Uint8Array.from(hex.match(/../g) ?? [], (h) => parseInt(h, 16));

async function hashPassword(password: string, salt: Uint8Array): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(password),
    'PBKDF2',
    false,
    ['deriveBits'],
  );
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', hash: 'SHA-256', salt, iterations: PBKDF2_ITERATIONS },
    key,
    256,
  );
  return toHex(bits);
}

async function sha256Hex(text: string): Promise<string> {
  return toHex(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text)));
}

/** Comparacion en tiempo constante de dos hex del mismo largo. */
function sameHex(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

async function readBody(request: Request): Promise<Record<string, unknown>> {
  try {
    const body: unknown = await request.json();
    if (body && typeof body === 'object') return body as Record<string, unknown>;
  } catch {
    // cae al error de abajo: el cuerpo no era JSON
  }
  throw new HttpError(400, 'El cuerpo debe ser JSON.');
}

function usernameOf(body: Record<string, unknown>): string {
  const raw = body.username;
  const username = typeof raw === 'string' ? raw.trim().toLowerCase() : '';
  if (!USERNAME.test(username)) {
    throw new HttpError(400, 'El usuario debe tener de 3 a 20 letras, números o guion bajo.');
  }
  return username;
}

async function createSession(env: Env, userId: number): Promise<string> {
  const token = toHex(crypto.getRandomValues(new Uint8Array(32)));
  await env.DB.prepare(
    'INSERT INTO sessions (token_hash, user_id, created_at) VALUES (?, ?, ?)',
  )
    .bind(await sha256Hex(token), userId, Date.now())
    .run();
  return token;
}

interface Account {
  id: number;
  username: string;
}

async function authenticate(request: Request, env: Env): Promise<Account> {
  const header = request.headers.get('authorization') ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  const row = token
    ? await env.DB.prepare(
        `SELECT u.id, u.username FROM sessions s
         JOIN users u ON u.id = s.user_id WHERE s.token_hash = ?`,
      )
        .bind(await sha256Hex(token))
        .first<Account>()
    : null;
  if (!row) throw new HttpError(401, 'Sesión no válida. Inicia sesión de nuevo.');
  return row;
}

async function findUser(env: Env, username: string): Promise<Account> {
  const row = await env.DB.prepare('SELECT id, username FROM users WHERE username = ?')
    .bind(username)
    .first<Account>();
  if (!row) throw new HttpError(404, 'No existe ese usuario.');
  return row;
}

async function register(request: Request, env: Env): Promise<Response> {
  const body = await readBody(request);
  const username = usernameOf(body);
  const password = typeof body.password === 'string' ? body.password : '';
  if (password.length < 8) {
    throw new HttpError(400, 'La contraseña debe tener al menos 8 caracteres.');
  }
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const result = await env.DB.prepare(
    'INSERT INTO users (username, pass_hash, salt, created_at) VALUES (?, ?, ?, ?) ON CONFLICT(username) DO NOTHING',
  )
    .bind(username, await hashPassword(password, salt), toHex(salt), Date.now())
    .run();
  if (result.meta.changes === 0) throw new HttpError(409, 'Ese usuario ya existe.');
  const id = result.meta.last_row_id;
  return json({ token: await createSession(env, id), username }, 201);
}

async function login(request: Request, env: Env): Promise<Response> {
  const body = await readBody(request);
  const username = usernameOf(body);
  const password = typeof body.password === 'string' ? body.password : '';
  const row = await env.DB.prepare(
    'SELECT id, pass_hash, salt FROM users WHERE username = ?',
  )
    .bind(username)
    .first<{ id: number; pass_hash: string; salt: string }>();
  const candidate = await hashPassword(
    password,
    row ? fromHex(row.salt) : new Uint8Array(16),
  );
  // El mismo mensaje para "no existe" y "clave incorrecta": no revela cuentas.
  if (!row || !sameHex(candidate, row.pass_hash)) {
    throw new HttpError(401, 'Usuario o contraseña incorrectos.');
  }
  return json({ token: await createSession(env, row.id), username });
}

async function friendsOf(env: Env, me: Account): Promise<Response> {
  const rows = await env.DB.prepare(
    `SELECT f.requester_id, f.status, r.username AS requester, a.username AS addressee
     FROM friendships f
     JOIN users r ON r.id = f.requester_id
     JOIN users a ON a.id = f.addressee_id
     WHERE f.requester_id = ?1 OR f.addressee_id = ?1
     ORDER BY f.created_at DESC`,
  )
    .bind(me.id)
    .all<{ requester_id: number; status: string; requester: string; addressee: string }>();

  const friends: string[] = [];
  const incoming: string[] = [];
  const outgoing: string[] = [];
  for (const row of rows.results) {
    const iAsked = row.requester_id === me.id;
    const other = iAsked ? row.addressee : row.requester;
    if (row.status === 'accepted') friends.push(other);
    else (iAsked ? outgoing : incoming).push(other);
  }
  return json({ friends, incoming, outgoing });
}

async function requestFriend(request: Request, env: Env, me: Account): Promise<Response> {
  const target = await findUser(env, usernameOf(await readBody(request)));
  if (target.id === me.id) throw new HttpError(400, 'No puedes agregarte a ti mismo.');

  const existing = await env.DB.prepare(
    `SELECT requester_id, status FROM friendships
     WHERE (requester_id = ?1 AND addressee_id = ?2) OR (requester_id = ?2 AND addressee_id = ?1)`,
  )
    .bind(me.id, target.id)
    .first<{ requester_id: number; status: string }>();

  if (existing?.status === 'accepted') throw new HttpError(409, 'Ya son amigos.');
  if (existing && existing.requester_id === me.id) {
    throw new HttpError(409, 'Ya enviaste la solicitud.');
  }
  if (existing) {
    // Esa persona ya te la habia enviado: pedirle lo mismo equivale a aceptar.
    await env.DB.prepare(
      "UPDATE friendships SET status = 'accepted' WHERE requester_id = ? AND addressee_id = ?",
    )
      .bind(target.id, me.id)
      .run();
    return json({ status: 'accepted' });
  }
  await env.DB.prepare(
    "INSERT INTO friendships (requester_id, addressee_id, status, created_at) VALUES (?, ?, 'pending', ?)",
  )
    .bind(me.id, target.id, Date.now())
    .run();
  return json({ status: 'pending' }, 201);
}

async function acceptFriend(request: Request, env: Env, me: Account): Promise<Response> {
  const target = await findUser(env, usernameOf(await readBody(request)));
  const result = await env.DB.prepare(
    `UPDATE friendships SET status = 'accepted'
     WHERE requester_id = ? AND addressee_id = ? AND status = 'pending'`,
  )
    .bind(target.id, me.id)
    .run();
  if (result.meta.changes === 0) throw new HttpError(404, 'No hay una solicitud de esa persona.');
  return json({ status: 'accepted' });
}

/** Quita un amigo, cancela una solicitud enviada o rechaza una recibida. */
async function removeFriend(username: string, env: Env, me: Account): Promise<Response> {
  const target = await findUser(env, username);
  const result = await env.DB.prepare(
    `DELETE FROM friendships
     WHERE (requester_id = ?1 AND addressee_id = ?2) OR (requester_id = ?2 AND addressee_id = ?1)`,
  )
    .bind(me.id, target.id)
    .run();
  if (result.meta.changes === 0) throw new HttpError(404, 'No hay relación con esa persona.');
  return json({ ok: true });
}

async function route(request: Request, env: Env): Promise<Response> {
  const { pathname } = new URL(request.url);
  const method = request.method;

  if (method === 'POST' && pathname === '/register') return register(request, env);
  if (method === 'POST' && pathname === '/login') return login(request, env);

  const me = await authenticate(request, env);
  if (method === 'GET' && pathname === '/me') return json({ username: me.username });
  if (method === 'POST' && pathname === '/logout') {
    const token = (request.headers.get('authorization') ?? '').slice(7);
    await env.DB.prepare('DELETE FROM sessions WHERE token_hash = ?')
      .bind(await sha256Hex(token))
      .run();
    return json({ ok: true });
  }
  if (method === 'GET' && pathname === '/friends') return friendsOf(env, me);
  if (method === 'POST' && pathname === '/friends/request') return requestFriend(request, env, me);
  if (method === 'POST' && pathname === '/friends/accept') return acceptFriend(request, env, me);
  if (method === 'DELETE' && pathname.startsWith('/friends/')) {
    return removeFriend(decodeURIComponent(pathname.slice('/friends/'.length)).toLowerCase(), env, me);
  }
  throw new HttpError(404, 'Ruta no encontrada.');
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      return await route(request, env);
    } catch (error) {
      if (error instanceof HttpError) return json({ error: error.message }, error.status);
      // Un fallo inesperado debe verse en los logs de Cloudflare, no taparse.
      console.error(error);
      return json({ error: 'Error interno del servidor.' }, 500);
    }
  },
} satisfies ExportedHandler<Env>;
