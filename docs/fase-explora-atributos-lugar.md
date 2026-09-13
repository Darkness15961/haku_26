# Atributos de `lugar` — pureza relacional

## Regla estricta (vigente)

```
departamento → provincia → distrito → lugar
```

- `lugar` solo tiene **`distrito_id` NOT NULL**.
- **No** existe `provincia_id` en `lugar`.
- La provincia se obtiene siempre: `lugar → distrito → provincia`.
- Sin distritos comodín ni “sin distrito”.

Migración: `supabase/migrations/20260913020000_lugar_solo_distrito.sql`  
(requiere `db push`).

## Núcleo de lugar

| Campo | Rol |
|-------|-----|
| `distrito_id` | Obligatorio (ancla territorial) |
| `nombre`, `descripcion`, `foto_portada` | Identidad |
| `latitud` / `longitud` (+ `ubicacion`) | Punto en mapa |
| `acceso` | Cómo se llega |
| `altitud` | Opcional |
| `usuario_id`, `estado`, fechas | Sistema |

## Formulario — paso ubicación (3 vías)

1. **Usar mi ubicación** — GPS  
2. **Buscar o marcar en el mapa** — centrado al distrito + buscador + tap  
3. **Escribir coordenadas** — lat/lon decimal (avanzado)

La columna BD `ubicacion` (PostGIS) **no se pide al usuario**: se llena sola desde lat/lon para cercanía en el mapa.

## Explora / islas

Las islas siguen siendo provincias en UI; el listado agrupa por  
`lugar.distrito.provincia.codigo` (join), no por columna en `lugar`.
