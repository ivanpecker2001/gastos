-- Ejecutar en Supabase > SQL Editor
create table if not exists gastos (
  id bigint generated always as identity primary key,
  descripcion text not null,
  monto numeric(12,2) not null,
  fecha date not null default current_date,
  created_at timestamptz default now()
);

alter table gastos enable row level security;

-- SOLO PARA PRUEBA: cualquiera con la URL puede leer/escribir. Reemplazar por políticas con login.
create policy "prueba_lectura" on gastos for select using (true);
create policy "prueba_insert"  on gastos for insert with check (true);
