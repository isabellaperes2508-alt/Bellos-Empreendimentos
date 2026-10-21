import assert from 'node:assert/strict';
import {scopedProfile,propertyAction,emptyData,accountsFor} from '../supabase/functions/bellos-empreendimentos/domain.js';
const p={id:'one',lots:[{id:1},{id:2}],data:emptyData()};
const users=[{id:'a',property_id:'one',role:'broker',units:[]},{id:'b',property_id:'one',role:'broker',units:[]},{id:'o',property_id:'one',role:'owner',created_by:'a',units:[1]},{id:'q',property_id:'one',role:'owner',created_by:'b',units:[2]}];
p.data.leads=[{id:1,ownerId:'a'},{id:2,ownerId:'b'}];p.data.payments=[{ownerId:'o',lot:1},{ownerId:'q',lot:2}];p.data.documents=[{ownerId:'o'},{ownerId:'q'},{audience:'condominio'}];p.data.memberRequests=[{ownerId:'o'},{ownerId:'q'}];
const broker=scopedProfile(users,p,users[0]);assert.equal(broker.data.leads.length,1);assert.equal(broker.data.payments.length,0);assert.equal(accountsFor(users,users[0],'one').length,1);assert.equal(broker.data.owners[0].id,'o');
const owner=scopedProfile(users,p,users[2]);assert.equal(owner.lots.length,1);assert.equal(owner.data.payments.length,1);assert.equal(owner.data.documents.length,2);assert.equal(owner.data.memberRequests.length,1);assert.equal(owner.data.leads.length,0);
assert.throws(()=>propertyAction(users,p,users[0],{action:'lead',id:2}),/outro corretor/);assert.throws(()=>propertyAction(users,p,users[2],{action:'paid',id:1}),/gestão/);assert.throws(()=>propertyAction(users,p,users[0],{action:'units'}),/gestão/);console.log('PASS: owner filtering, broker filtering, account ownership and mutation role boundaries.');
