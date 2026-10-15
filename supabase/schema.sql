-- Esquema de Mis Gastos. Ejecutar completo en Supabase > SQL Editor.
-- Se puede volver a ejecutar sin perder datos.

-- Un período arranca cuando cobrás y queda abierto (fin null) hasta que lo cerrás.
create table if not exists periodos (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  nombre text not null,
  inicio date not null,
  fin date,
  created_at timestamptz not null default now(),
  constraint periodos_fechas check (fin is null or fin >= inicio)
);

-- Solo puede haber un período abierto por usuario.
create unique index if not exists periodos_un_abierto on periodos (user_id) where fin is null;

-- Movimientos de plata de cada período, además de los gastos:
--   blanco, negro, extra: ingresos (medio = dónde entró la plata)
--   retiro: de la cuenta al efectivo · deposito: del efectivo a la cuenta
--   dolares: compra de dólares (monto = pesos pagados, medio = con qué se pagó)
create table if not exists movimientos (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  periodo_id bigint not null references periodos on delete cascade,
  fecha date not null default current_date,
  tipo text not null,
  medio text not null check (medio in ('cuenta', 'efectivo')),
  monto numeric(12,2) not null check (monto > 0),
  usd numeric(12,2),
  nota text,
  created_at timestamptz not null default now()
);

alter table movimientos drop constraint if exists movimientos_tipo_check;
alter table movimientos add constraint movimientos_tipo_check
  check (tipo in ('blanco', 'negro', 'extra', 'retiro', 'deposito', 'dolares'));
alter table movimientos drop constraint if exists movimientos_usd_check;
alter table movimientos add constraint movimientos_usd_check
  check ((tipo = 'dolares') = (usd is not null and usd > 0));

-- Categorías editables de cada usuario. icono es una clave que la app traduce a un ícono.
create table if not exists categorias (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  nombre text not null,
  icono text not null default 'label',
  created_at timestamptz not null default now(),
  unique (user_id, nombre)
);

-- Los gastos no se atan a un período: cuentan en el período que contiene su fecha.
-- Una categoría con gastos no se puede borrar (on delete restrict).
create table if not exists gastos (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  fecha date not null default current_date,
  descripcion text not null,
  monto numeric(12,2) not null check (monto > 0),
  forma_pago text not null,
  categoria_id bigint not null references categorias on delete restrict,
  created_at timestamptz not null default now()
);

create index if not exists periodos_user_inicio on periodos (user_id, inicio);
create index if not exists movimientos_periodo on movimientos (periodo_id);
create index if not exists movimientos_user_tipo on movimientos (user_id, tipo);
create index if not exists gastos_user_fecha on gastos (user_id, fecha);
create index if not exists gastos_categoria on gastos (categoria_id);

grant select, insert, update, delete on periodos, movimientos, categorias, gastos to authenticated;

-- Cada usuario ve y modifica solo sus propias filas.
alter table periodos enable row level security;
alter table movimientos enable row level security;
alter table categorias enable row level security;
alter table gastos enable row level security;

drop policy if exists "propios" on periodos;
create policy "propios" on periodos for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "propios" on movimientos;
create policy "propios" on movimientos for all to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and exists (select 1 from periodos p where p.id = periodo_id and p.user_id = (select auth.uid()))
  );

drop policy if exists "propios" on categorias;
create policy "propios" on categorias for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "propios" on gastos;
create policy "propios" on gastos for all to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and exists (select 1 from categorias c where c.id = categoria_id and c.user_id = (select auth.uid()))
  );
