create table if not exists public.bellos_emp_properties(id text primary key, profile jsonb not null, revision bigint not null default 1);
create table if not exists public.bellos_emp_users(id uuid primary key default gen_random_uuid(), property_id text references public.bellos_emp_properties(id), username text not null, name text not null,email text not null default '',role text not null check(role in ('superadmin','manager','broker','owner')),password_hash text not null, enabled boolean not null default true,created_by uuid,units jsonb not null default '[]',membership text not null default 'proprietario',must_change boolean not null default true, check((role='superadmin' and property_id is null) or (role<>'superadmin' and property_id is not null)));
create unique index if not exists bellos_emp_username on public.bellos_emp_users(coalesce(property_id,''),username);
create unique index if not exists bellos_emp_single_admin on public.bellos_emp_users(role) where role='superadmin';
create table if not exists public.bellos_emp_sessions(token_hash text primary key,user_id uuid not null references public.bellos_emp_users(id) on delete cascade,created_at timestamptz not null default now(),last_seen timestamptz not null default now());
create table if not exists public.bellos_emp_attempts(key text primary key,count integer not null,until_at timestamptz not null);
create table if not exists public.bellos_emp_activation(token_hash text primary key,expires_at timestamptz not null,used_at timestamptz);
create table if not exists public.bellos_emp_audit(id bigint generated always as identity primary key,at timestamptz not null default now(),user_id uuid,property_id text,event text not null);
alter table public.bellos_emp_properties enable row level security;
alter table public.bellos_emp_users enable row level security;
alter table public.bellos_emp_sessions enable row level security;
alter table public.bellos_emp_attempts enable row level security;
alter table public.bellos_emp_activation enable row level security;
alter table public.bellos_emp_audit enable row level security;
revoke all on public.bellos_emp_properties,public.bellos_emp_users,public.bellos_emp_sessions,public.bellos_emp_attempts,public.bellos_emp_activation,public.bellos_emp_audit from anon,authenticated;
grant all on public.bellos_emp_properties,public.bellos_emp_users,public.bellos_emp_sessions,public.bellos_emp_attempts,public.bellos_emp_activation,public.bellos_emp_audit to service_role;
grant usage,select on sequence public.bellos_emp_audit_id_seq to service_role;

create or replace function public.bellos_emp_auth(input jsonb, session_token text default '', ip_key text default '') returns jsonb language plpgsql security invoker set search_path='' as $$
declare op text:=input->>'op'; u public.bellos_emp_users%rowtype; rawtoken text; hashed text; k text; attempt_count int; activation public.bellos_emp_activation%rowtype; existing_s public.bellos_emp_sessions%rowtype; login_name text; tenant text; result jsonb;
begin
 delete from public.bellos_emp_attempts where until_at<now();
 delete from public.bellos_emp_sessions where created_at<now()-interval '12 hours' or last_seen<now()-interval '30 minutes';
 if op in ('login','activate') then
  k:='ip:'||ip_key;
  insert into public.bellos_emp_attempts values(k,1,now()+interval '15 minutes') on conflict(key) do update set count=bellos_emp_attempts.count+1 returning count into attempt_count;
  if attempt_count>100 then return jsonb_build_object('status',429,'body',jsonb_build_object('error','Muitas tentativas. Aguarde 15 minutos.')); end if;
 end if;
 if op='activate' then
  select * into activation from public.bellos_emp_activation where token_hash=encode(extensions.digest(coalesce(input->>'activation',''),'sha256'),'hex') for update;
  if not found or activation.used_at is not null or activation.expires_at<now() or exists(select 1 from public.bellos_emp_users where role='superadmin') then return jsonb_build_object('status',403,'body',jsonb_build_object('error','Link de ativação inválido ou já utilizado.')); end if;
  if coalesce(input->>'pin','') !~ '^[0-9]{6}$' then return jsonb_build_object('status',400,'body',jsonb_build_object('error','A senha deve ter seis números.')); end if;
  insert into public.bellos_emp_users(username,name,email,role,password_hash,must_change) values('isabella.cleto','Isabella Cleto','isabellaperes2508@gmail.com','superadmin',extensions.crypt(input->>'pin',extensions.gen_salt('bf',10)),false) returning * into u;
  update public.bellos_emp_activation set used_at=now() where token_hash=activation.token_hash;
  return jsonb_build_object('status',200,'body',jsonb_build_object('username',u.username));
 end if;
 if op='login' then
  login_name:=lower(trim(coalesce(input->>'username',''))); tenant:=coalesce(input->>'propertyId','');
  k:='account:'||encode(extensions.digest(tenant||':'||login_name,'sha256'),'hex');
  insert into public.bellos_emp_attempts values(k,1,now()+interval '15 minutes') on conflict(key) do update set count=bellos_emp_attempts.count+1 returning count into attempt_count;
  if attempt_count>5 then return jsonb_build_object('status',429,'body',jsonb_build_object('error','Muitas tentativas. Aguarde 15 minutos.')); end if;
  select * into u from public.bellos_emp_users where coalesce(property_id,'')=tenant and bellos_emp_users.username=login_name;
  if u.id is null or not u.enabled or coalesce(input->>'pin','') !~ '^[0-9]{6}$' or extensions.crypt(input->>'pin',u.password_hash)<>u.password_hash then return jsonb_build_object('status',401,'body',jsonb_build_object('error','Usuário ou senha incorretos.')); end if;
  delete from public.bellos_emp_attempts where key=k;
  rawtoken:=encode(extensions.gen_random_bytes(32),'hex'); hashed:=encode(extensions.digest(rawtoken,'sha256'),'hex');
  insert into public.bellos_emp_sessions(token_hash,user_id) values(hashed,u.id);
  return jsonb_build_object('status',200,'body',jsonb_build_object('user',to_jsonb(u)-'password_hash','token',rawtoken));
 end if;
 hashed:=encode(extensions.digest(coalesce(session_token,''),'sha256'),'hex');
 if op='logout' then delete from public.bellos_emp_sessions where token_hash=hashed;return jsonb_build_object('status',200,'body',jsonb_build_object('ok',true)); end if;
 select * into existing_s from public.bellos_emp_sessions where token_hash=hashed;
 if existing_s.user_id is null then return jsonb_build_object('status',401,'body',jsonb_build_object('error','Entre novamente para continuar.')); end if;
 select * into u from public.bellos_emp_users where id=existing_s.user_id and enabled=true;
 if u.id is null then return jsonb_build_object('status',401,'body',jsonb_build_object('error','Entre novamente para continuar.')); end if;
 update public.bellos_emp_sessions set last_seen=now() where token_hash=hashed;
 if op='password' then
  k:='password:'||u.id::text;
  insert into public.bellos_emp_attempts values(k,1,now()+interval '15 minutes') on conflict(key) do update set count=bellos_emp_attempts.count+1 returning count into attempt_count;
  if attempt_count>5 then return jsonb_build_object('status',429,'body',jsonb_build_object('error','Aguarde 15 minutos.')); end if;
  if coalesce(input->>'current','') !~ '^[0-9]{6}$' or extensions.crypt(input->>'current',u.password_hash)<>u.password_hash then return jsonb_build_object('status',400,'body',jsonb_build_object('error','Senha atual incorreta.')); end if;
  if coalesce(input->>'pin','') !~ '^[0-9]{6}$' or input->>'pin'=input->>'current' then return jsonb_build_object('status',400,'body',jsonb_build_object('error','Escolha uma nova senha de seis números.')); end if;
  update public.bellos_emp_users set password_hash=extensions.crypt(input->>'pin',extensions.gen_salt('bf',10)),must_change=false where id=u.id;
  delete from public.bellos_emp_sessions where user_id=u.id;
  return jsonb_build_object('status',200,'body',jsonb_build_object('ok',true));
 end if;
 if op<>'session' then return jsonb_build_object('status',400,'body',jsonb_build_object('error','Operação inválida.'));end if;
 if u.must_change then return jsonb_build_object('status',403,'body',jsonb_build_object('error','Defina uma nova senha para continuar.')); end if;
 return jsonb_build_object('status',200,'body',to_jsonb(u)-'password_hash');
end;$$;
revoke all on function public.bellos_emp_auth(jsonb,text,text) from public,anon,authenticated;
grant execute on function public.bellos_emp_auth(jsonb,text,text) to service_role;

create or replace function public.bellos_emp_account(actor_id uuid,pid text,input jsonb) returns jsonb language plpgsql security invoker set search_path='' as $$
declare actor public.bellos_emp_users%rowtype; target public.bellos_emp_users%rowtype; uname text; base text; counter int:=2; newrole text; prop jsonb; unit jsonb;
begin
 select * into actor from public.bellos_emp_users where id=actor_id and enabled=true;
 if actor.id is null or actor.must_change or actor.role not in ('superadmin','manager','broker') or actor.role<>'superadmin' and actor.property_id<>pid then return jsonb_build_object('status',403,'body',jsonb_build_object('error','Acesso não autorizado.'));end if;
 select profile into prop from public.bellos_emp_properties where id=pid for update;
 if prop is null then return jsonb_build_object('status',404,'body',jsonb_build_object('error','Empreendimento não encontrado.'));end if;
 if coalesce(input->>'id','')<>'' then
  select * into target from public.bellos_emp_users where id=(input->>'id')::uuid and property_id=pid;
  if target.id is null or actor.role='broker' and (target.role<>'owner' or target.created_by is distinct from actor.id) then return jsonb_build_object('status',403,'body',jsonb_build_object('error','Cadastro de outro responsável.')); end if;
 end if;
 if input->>'action'='toggle' then
  if target.id is null or target.id=actor.id then return jsonb_build_object('status',400,'body',jsonb_build_object('error','Cadastro inválido.'));end if;
  update public.bellos_emp_users set enabled=not enabled where id=target.id;delete from public.bellos_emp_sessions where user_id=target.id;
 elsif input->>'action'='reset' then
  if target.id is null or coalesce(input->>'pin','') !~ '^[0-9]{6}$' then return jsonb_build_object('status',400,'body',jsonb_build_object('error','Senha inválida.'));end if;
  update public.bellos_emp_users set password_hash=extensions.crypt(input->>'pin',extensions.gen_salt('bf',10)),must_change=true where id=target.id;delete from public.bellos_emp_sessions where user_id=target.id;
 else
  if length(trim(coalesce(input->>'name','')))<3 or length(input->>'name')>100 or length(coalesce(input->>'email',''))>254 or jsonb_typeof(coalesce(input->'units','[]'))<>'array' then return jsonb_build_object('status',400,'body',jsonb_build_object('error','Dados inválidos.'));end if;
  for unit in select value from jsonb_array_elements(coalesce(input->'units','[]')) loop
   if not exists(select 1 from jsonb_array_elements(prop->'lots') l where l->'id'=unit) then return jsonb_build_object('status',400,'body',jsonb_build_object('error','Unidade inválida.'));end if;
  end loop;
  if target.id is not null then update public.bellos_emp_users set name=trim(input->>'name'),email=coalesce(input->>'email',''),units=coalesce(input->'units','[]'),membership=case when input->>'membership'='morador' then 'morador' else 'proprietario' end where id=target.id;
  else
   newrole:=input->>'role';
   if newrole is null or newrole not in ('manager','broker','owner') or actor.role='broker' and newrole<>'owner' then return jsonb_build_object('status',403,'body',jsonb_build_object('error','Perfil não permitido.'));end if;
   if coalesce(input->>'pin','') !~ '^[0-9]{6}$' or coalesce(input->>'usernameBase','') !~ '^[a-z]+\.[a-z]+$' then return jsonb_build_object('status',400,'body',jsonb_build_object('error','Informe nome, sobrenome e senha de seis números.'));end if;
   base:=input->>'usernameBase';uname:=base;
   while exists(select 1 from public.bellos_emp_users where property_id=pid and username=uname) loop uname:=base||counter::text;counter:=counter+1;end loop;
   insert into public.bellos_emp_users(property_id,username,name,email,role,password_hash,created_by,units,membership) values(pid,uname,trim(input->>'name'),coalesce(input->>'email',''),newrole,extensions.crypt(input->>'pin',extensions.gen_salt('bf',10)),actor.id,coalesce(input->'units','[]'),case when input->>'membership'='morador' then 'morador' else 'proprietario' end) returning * into target;
   return jsonb_build_object('status',200,'body',jsonb_build_object('ok',true,'username',uname,'id',target.id));
  end if;
 end if;
 return jsonb_build_object('status',200,'body',jsonb_build_object('ok',true));
end;$$;
revoke all on function public.bellos_emp_account(uuid,text,jsonb) from public,anon,authenticated;
grant execute on function public.bellos_emp_account(uuid,text,jsonb) to service_role;
