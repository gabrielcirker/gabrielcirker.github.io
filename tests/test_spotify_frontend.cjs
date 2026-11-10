/* Dependency-free DOM fixture smoke test; not a substitute for browser/layout QA. */
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=__dirname+'/../docs/spotify-title-lab/';
const html=fs.readFileSync(root+'index.html','utf8');
const registry=new Map();
class Element {
 constructor(tag='div',attrs={}){this.tagName=tag;this.attrs=attrs;this.dataset={};for(const [k,v]of Object.entries(attrs))if(k.startsWith('data-'))this.dataset[k.slice(5).replace(/-([a-z])/g,(_,c)=>c.toUpperCase())]=v;this.value=attrs.value||'';this.textContent='';this.listeners={};this.options=[];this._html='';}
 set innerHTML(text){this._html=String(text);parse(this._html);}
 get innerHTML(){return this._html;}
 insertAdjacentHTML(where,text){this._html+=text;parse(text);}
 add(option){this.options.push(option);if(this.options.length===1)this.value=option.value;}
 addEventListener(event,fn){this.listeners[event]=fn;}
 querySelectorAll(selector){return children(this._html,selector);}
 setAttribute(k,v){this.attrs[k]=v;}
 getAttribute(k){return this.attrs[k];}
 focus(){} select(){} remove(){}
}
function attrs(text){const r={};for(const m of text.matchAll(/([\w-]+)(?:="([^"]*)")?/g))r[m[1]]=m[2]||'';return r;}
function parse(text){for(const m of text.matchAll(/<([a-z][\w-]*)\b([^>]*)>/gi)){const a=attrs(m[2]);if(a.id&&!registry.has('#'+a.id))registry.set('#'+a.id,new Element(m[1],a));if('data-share-project' in a)registry.set('[data-share-project]',new Element(m[1],a));}for(const m of text.matchAll(/<select\b([^>]*)>([\s\S]*?)<\/select>/g)){const a=attrs(m[1]),el=registry.get('#'+a.id);if(el){el.options=[...m[2].matchAll(/<option\b([^>]*)>([^<]*)/g)].map(o=>({value:attrs(o[1]).value||'',text:o[2]}));el.value=el.options[0]?.value||'';}}}
function children(text,selector){return [...text.matchAll(/<([a-z][\w-]*)\b([^>]*)>/gi)].map(m=>new Element(m[1],attrs(m[2]))).filter(e=>selector.startsWith('.')?(e.attrs.class||'').split(' ').includes(selector.slice(1)):e.tagName===selector);}
parse(html);registry.set('.sources',new Element());
const errors=[];const pending=[];
const context={console:{error:e=>errors.push(String(e)),log:()=>{}},location:{hash:'',search:'',replace:()=>{}},navigator:{clipboard:{writeText:async()=>{}}},Option:function(text,value){this.text=text;this.value=String(value);},document:{querySelector:s=>{if(!registry.has(s))throw Error('Unknown selector '+s);return registry.get(s)},querySelectorAll:s=>{return [...registry.values()].flatMap(e=>e.querySelectorAll(s));}},fetch:path=>{const p=Promise.resolve({ok:true,status:200,json:()=>JSON.parse(fs.readFileSync(root+path,'utf8'))});pending.push(p);return p;},Intl,Map,Set,Math,Number,String,Array,Object,JSON};
vm.createContext(context);vm.runInContext(fs.readFileSync(root+'lab.js','utf8'),context,{timeout:10000});
(async()=>{await Promise.all(pending);await new Promise(r=>setImmediate(r));assert.deepEqual(errors,[],'Renderer errors');
const get=s=>registry.get(s);
const referenceSources=JSON.parse(fs.readFileSync(root+'data/external.json','utf8')).sources;
const renderedSources=get('.sources').innerHTML;
for(const source of referenceSources){assert.ok(renderedSources.includes(source.name),'Source name retained');assert.ok(renderedSources.includes(source.url.replaceAll('&','&amp;')),'Source link retained');assert.ok(renderedSources.includes(source.license),'Source license retained');if(source.retrievedAt)assert.ok(!renderedSources.includes(source.retrievedAt),'Retrieval timestamp omitted');}
assert.doesNotMatch(renderedSources,/Retrieved|Accessed/i);
assert.match(get('#summary').innerHTML,/44,091/);assert.match(get('#track-count').textContent,/11,769/);assert.match(get('#track-detail').innerHTML,/<svg/);assert.match(get('#prediction-table').innerHTML,/7.5%/);assert.match(get('#network-chart').innerHTML,/<svg/);assert.doesNotMatch(get('#network-detail').innerHTML,/undefined/);
get('#track-search').value='zzzzzz-nothing-match';get('#track-search').listeners.input();assert.match(get('#track-count').textContent,/0 matching/);assert.match(get('#track-list').innerHTML,/No tracks match/);
get('#track-search').value='';get('#life-filter').value='steadyPattern';get('#life-filter').listeners.change();assert.match(get('#track-count').textContent,/494 matching/);
get('#time-scale').value='weekly';get('#time-scale').listeners.change();assert.match(get('#pulse').innerHTML,/by week/);
get('#fold-select').value='1';get('#fold-select').listeners.change();assert.match(get('#prediction-chart').innerHTML,/Training through/);
get('#edge-filter').value='999999';get('#edge-filter').listeners.input();assert.match(get('#network-chart').innerHTML,/0 connections/);
assert.match(get('#community-content').innerHTML,/Shares are normalized/);assert.doesNotMatch(get('#community-chart').innerHTML,/NaN|undefined/);get('#community-sort').value='lift';get('#community-sort').listeners.change();assert.match(get('#community-table').innerHTML,/<table/);
assert.match(get('#releases-content').innerHTML,/<svg/);assert.match(get('#acoustic-content').innerHTML,/<svg/);assert.doesNotMatch(get('#acoustic-content').innerHTML,/NaN|undefined/);
await get('[data-share-project]').listeners.click();assert.equal(get('#share-status').textContent,'Project link copied.');context.navigator.clipboard.writeText=async()=>{throw Error('clipboard unavailable')};await get('[data-share-project]').listeners.click();assert.equal(get('#share-fallback').value,'https://gabrielcirker.github.io/spotify-title-lab/');assert.equal(get('#share-fallback').hidden,false);
console.log('Frontend fixture checks passed: renderer, filters, empty states, folds, network threshold, community sort, release and acoustic output.');})().catch(e=>{console.error(e);process.exitCode=1;});
