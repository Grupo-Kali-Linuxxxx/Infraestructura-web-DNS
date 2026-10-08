const http = require('node:http');
const {randomBytes} = require('node:crypto');
const fs = require('node:fs');
const app = process.env.APP_NAME || 'App 1';
const cookieName = process.env.COOKIE_NAME || 'app1.sid';
const sessions = new Map();
const ttl = 15 * 60 * 1000;
const timer = setInterval(() => { for (const [id,s] of sessions) if(s.expires <= Date.now()) sessions.delete(id); },60000);
timer.unref();
const cookie = (id, age=900) => `${cookieName}=${id}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${age}`;
const server = http.createServer((req,res) => {
  const url = new URL(req.url, 'http://localhost');
  const path = url.pathname;
  res.setHeader('Cache-Control','no-store');
  res.setHeader('X-Content-Type-Options','nosniff');
  const json = (status,data) => {res.writeHead(status,{'Content-Type':'application/json; charset=utf-8'}); res.end(JSON.stringify(data));};
  if(path === '/health') return json(200,{status:'ok',app});
  if(path === '/diagnostico') return json(200,{app,method:req.method,path,host:req.headers.host,proxy:req.socket.remoteAddress,client:req.headers['x-real-ip'],protocol:req.headers['x-forwarded-proto']});
  if(path === '/pruebas/502') return req.socket.destroy();
  if(path === '/pruebas/500') {res.writeHead(500);return res.end('Error controlado');}
  if(path.startsWith('/api/')) {
    // Rechazar modificaciones cross-origin. Los clientes curl no necesitan Origin.
    if(req.headers.origin && req.headers.origin !== `http://${req.headers.host}` && req.method !== 'GET') return json(403,{error:'Origen no permitido'});
    const raw = (req.headers.cookie || '').split(';').map(x=>x.trim()).find(x=>x.startsWith(cookieName+'='));
    const id = raw ? raw.slice(cookieName.length+1) : '';
    let s = sessions.get(id);
    if(s && s.expires <= Date.now()) {sessions.delete(id);s=null;}
    if(path === '/api/info') return json(200,{app,technology:'Node.js HTTP',store:'Memoria del proceso'});
    if(path === '/api/sesion' && req.method === 'GET') return json(200,{app,activa:!!s,contador:s?.count || 0});
    if(path === '/api/sesion' && req.method === 'POST') {
      if(s) sessions.delete(id);
      const next = randomBytes(32).toString('hex');
      sessions.set(next,{count:0,expires:Date.now()+ttl});
      res.setHeader('Set-Cookie',cookie(next));return json(201,{app,activa:true,contador:0});
    }
    if(path === '/api/sesion/incrementar' && req.method === 'POST') {
      if(!s) return json(409,{error:'Primero crea una sesión'});
      // Sin await: lectura y modificación ocurren juntas en el event loop.
      s.count++; return json(200,{app,activa:true,contador:s.count});
    }
    if(path === '/api/sesion' && req.method === 'DELETE') {
      sessions.delete(id);res.setHeader('Set-Cookie',cookie('',0));return json(200,{app,activa:false,contador:0});
    }
    return json(404,{error:'Ruta API no encontrada'});
  }
  if((path === '/' || path === '/index.html' || path === '/sesiones') && ['GET','HEAD'].includes(req.method)) {
    res.writeHead(200,{'Content-Type':'text/html; charset=utf-8'});
    return res.end(req.method === 'HEAD' ? '' : fs.readFileSync('/app/index.html','utf8').replaceAll('__APP__',app));
  }
  res.writeHead(404,{'Content-Type':'text/plain; charset=utf-8'});res.end('Ruta no encontrada');
});
server.listen(3000,'0.0.0.0',()=>console.log(`${app} escuchando en 3000`));
process.on('SIGTERM',()=>{server.close(()=>process.exit(0));setTimeout(()=>process.exit(1),8000).unref();});
