const fs=require('node:fs');const path=require('node:path');const vm=require('node:vm');const crypto=require('node:crypto');
const root=__dirname;const manifest=JSON.parse(fs.readFileSync(path.join(root,'wasm-parts.json')));
const context={ReadableStream,Response,Blob,WebAssembly,console,setTimeout,requestAnimationFrame:(fn)=>setTimeout(fn,0),fetch:async(file)=>new Response(fs.readFileSync(path.join(root,'dist',file))),window:{}};
vm.createContext(context);vm.runInContext(fs.readFileSync(path.join(root,'dist/index.js'),'utf8'),context);
(async()=>{
 const response=await context.window.Engine.load('index',manifest.size);const buf=Buffer.from(await response.arrayBuffer());
 if(buf.length!==manifest.size||crypto.createHash('sha256').update(buf).digest('hex')!==manifest.sha256)throw new Error('WASM reconstruído inválido');
 await WebAssembly.compile(buf);
 const html=fs.readFileSync(path.join(root,'dist/index.html'),'utf8');
 const pckSize=html.match(/'index\.pck':(\d+)/);
 if(!pckSize||Number(pckSize[1])!==fs.statSync(path.join(root,'dist/index.pck')).size)throw new Error('Tamanho do PCK no carregador está desatualizado');
 for(const filename of fs.readdirSync(path.join(root,'dist'))){if(fs.statSync(path.join(root,'dist',filename)).size>25*1024*1024)throw new Error('Arquivo excede limite de hospedagem');}
 console.log('Loader verificado: SHA256 original, WASM compilável e assets abaixo do limite.');
})().catch(error=>{console.error(error);process.exitCode=1;});
