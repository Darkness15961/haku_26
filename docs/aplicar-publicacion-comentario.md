# Aplicar comentarios de publicación (VPS / Supabase self-host)

Migración: `supabase/migrations/20260924160000_publicacion_comentario.sql`

## Por qué no se hizo `db push` desde aquí

- CLI `supabase` **no está instalada** en este entorno.
- El proyecto **no está linkeado** (`supabase/.temp` ausente).
- Host productivo: `https://supabase.haku.best` (self-host).

## Cómo aplicar (elige una)

### A) SQL Editor / psql en el VPS

1. Abre el SQL Editor de tu Supabase (o `psql` al Postgres de Haku).
2. Ejecuta el contenido completo de  
   `supabase/migrations/20260924160000_publicacion_comentario.sql`
3. Verifica:

```sql
select to_regclass('public.publicacion_comentario');
```

### B) CLI local (cuando instales Supabase CLI)

```bash
# Windows (scoop/choco) o npm: npm i -g supabase
supabase link --project-ref <tu-ref>
supabase db push
```

Tras aplicar la migración, hot restart de la app: comentarios en el feed deberían listar/crear/borrar.
