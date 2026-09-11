# -*- coding: utf-8 -*-
"""Genera fragmento SQL de seed ISO 3166-1 (nombres en español)."""
from collections import Counter
from pathlib import Path

paises = [
    ("AF", "Afganistán"), ("AL", "Albania"), ("DE", "Alemania"), ("AD", "Andorra"),
    ("AO", "Angola"), ("AI", "Anguila"), ("AQ", "Antártida"), ("AG", "Antigua y Barbuda"),
    ("SA", "Arabia Saudita"), ("DZ", "Argelia"), ("AR", "Argentina"), ("AM", "Armenia"),
    ("AW", "Aruba"), ("AU", "Australia"), ("AT", "Austria"), ("AZ", "Azerbaiyán"),
    ("BS", "Bahamas"), ("BD", "Bangladés"), ("BB", "Barbados"), ("BH", "Baréin"),
    ("BE", "Bélgica"), ("BZ", "Belice"), ("BJ", "Benín"), ("BM", "Bermudas"),
    ("BY", "Bielorrusia"), ("BO", "Bolivia"), ("BA", "Bosnia y Herzegovina"),
    ("BW", "Botsuana"), ("BR", "Brasil"), ("BN", "Brunéi"), ("BG", "Bulgaria"),
    ("BF", "Burkina Faso"), ("BI", "Burundi"), ("BT", "Bután"), ("CV", "Cabo Verde"),
    ("KH", "Camboya"), ("CM", "Camerún"), ("CA", "Canadá"), ("QA", "Catar"),
    ("TD", "Chad"), ("CZ", "Chequia"), ("CL", "Chile"), ("CN", "China"), ("CY", "Chipre"),
    ("VA", "Ciudad del Vaticano"), ("CO", "Colombia"), ("KM", "Comoras"), ("CG", "Congo"),
    ("CD", "Congo (R.D.)"), ("KP", "Corea del Norte"), ("KR", "Corea del Sur"),
    ("CR", "Costa Rica"), ("CI", "Costa de Marfil"), ("HR", "Croacia"), ("CU", "Cuba"),
    ("CW", "Curazao"), ("DK", "Dinamarca"), ("DM", "Dominica"), ("EC", "Ecuador"),
    ("EG", "Egipto"), ("SV", "El Salvador"), ("AE", "Emiratos Árabes Unidos"),
    ("ER", "Eritrea"), ("SK", "Eslovaquia"), ("SI", "Eslovenia"), ("ES", "España"),
    ("US", "Estados Unidos"), ("EE", "Estonia"), ("SZ", "Esuatini"), ("ET", "Etiopía"),
    ("PH", "Filipinas"), ("FI", "Finlandia"), ("FJ", "Fiyi"), ("FR", "Francia"),
    ("GA", "Gabón"), ("GM", "Gambia"), ("GE", "Georgia"), ("GH", "Ghana"),
    ("GI", "Gibraltar"), ("GD", "Granada"), ("GR", "Grecia"), ("GL", "Groenlandia"),
    ("GP", "Guadalupe"), ("GU", "Guam"), ("GT", "Guatemala"), ("GF", "Guayana Francesa"),
    ("GG", "Guernsey"), ("GN", "Guinea"), ("GQ", "Guinea Ecuatorial"),
    ("GW", "Guinea-Bisáu"), ("GY", "Guyana"), ("HT", "Haití"), ("HN", "Honduras"),
    ("HK", "Hong Kong"), ("HU", "Hungría"), ("IN", "India"), ("ID", "Indonesia"),
    ("IQ", "Irak"), ("IR", "Irán"), ("IE", "Irlanda"), ("BV", "Isla Bouvet"),
    ("IM", "Isla de Man"), ("CX", "Isla de Navidad"), ("NF", "Isla Norfolk"),
    ("IS", "Islandia"), ("AX", "Islas Åland"), ("KY", "Islas Caimán"),
    ("CK", "Islas Cook"), ("FO", "Islas Feroe"), ("GS", "Islas Georgias del Sur"),
    ("HM", "Islas Heard y McDonald"), ("FK", "Islas Malvinas"),
    ("MP", "Islas Marianas del Norte"), ("MH", "Islas Marshall"),
    ("PN", "Islas Pitcairn"), ("SB", "Islas Salomón"), ("TC", "Islas Turcas y Caicos"),
    ("UM", "Islas Ultramarinas de EE.UU."), ("VG", "Islas Vírgenes Británicas"),
    ("VI", "Islas Vírgenes de EE.UU."), ("IL", "Israel"), ("IT", "Italia"),
    ("JM", "Jamaica"), ("JP", "Japón"), ("JE", "Jersey"), ("JO", "Jordania"),
    ("KZ", "Kazajistán"), ("KE", "Kenia"), ("KG", "Kirguistán"), ("KI", "Kiribati"),
    ("KW", "Kuwait"), ("LA", "Laos"), ("LS", "Lesoto"), ("LV", "Letonia"),
    ("LB", "Líbano"), ("LR", "Liberia"), ("LY", "Libia"), ("LI", "Liechtenstein"),
    ("LT", "Lituania"), ("LU", "Luxemburgo"), ("MO", "Macao"),
    ("MK", "Macedonia del Norte"), ("MG", "Madagascar"), ("MY", "Malasia"),
    ("MW", "Malaui"), ("MV", "Maldivas"), ("ML", "Malí"), ("MT", "Malta"),
    ("MA", "Marruecos"), ("MQ", "Martinica"), ("MU", "Mauricio"), ("MR", "Mauritania"),
    ("YT", "Mayotte"), ("MX", "México"), ("FM", "Micronesia"), ("MD", "Moldavia"),
    ("MC", "Mónaco"), ("MN", "Mongolia"), ("ME", "Montenegro"), ("MS", "Montserrat"),
    ("MZ", "Mozambique"), ("MM", "Myanmar"), ("NA", "Namibia"), ("NR", "Nauru"),
    ("NP", "Nepal"), ("NI", "Nicaragua"), ("NE", "Níger"), ("NG", "Nigeria"),
    ("NU", "Niue"), ("NO", "Noruega"), ("NC", "Nueva Caledonia"), ("NZ", "Nueva Zelanda"),
    ("OM", "Omán"), ("NL", "Países Bajos"), ("PK", "Pakistán"), ("PW", "Palaos"),
    ("PS", "Palestina"), ("PA", "Panamá"), ("PG", "Papúa Nueva Guinea"),
    ("PY", "Paraguay"), ("PE", "Perú"), ("PF", "Polinesia Francesa"), ("PL", "Polonia"),
    ("PT", "Portugal"), ("PR", "Puerto Rico"), ("GB", "Reino Unido"),
    ("CF", "República Centroafricana"), ("DO", "República Dominicana"),
    ("RE", "Reunión"), ("RW", "Ruanda"), ("RO", "Rumania"), ("RU", "Rusia"),
    ("EH", "Sáhara Occidental"), ("WS", "Samoa"), ("AS", "Samoa Americana"),
    ("BL", "San Bartolomé"), ("KN", "San Cristóbal y Nieves"), ("SM", "San Marino"),
    ("MF", "San Martín (Francia)"), ("PM", "San Pedro y Miquelón"),
    ("VC", "San Vicente y las Granadinas"), ("SH", "Santa Elena"), ("LC", "Santa Lucía"),
    ("ST", "Santo Tomé y Príncipe"), ("SN", "Senegal"), ("RS", "Serbia"),
    ("SC", "Seychelles"), ("SL", "Sierra Leona"), ("SG", "Singapur"),
    ("SX", "Sint Maarten"), ("SY", "Siria"), ("SO", "Somalia"), ("LK", "Sri Lanka"),
    ("ZA", "Sudáfrica"), ("SD", "Sudán"), ("SS", "Sudán del Sur"), ("SE", "Suecia"),
    ("CH", "Suiza"), ("SR", "Surinam"), ("SJ", "Svalbard y Jan Mayen"),
    ("TH", "Tailandia"), ("TW", "Taiwán"), ("TZ", "Tanzania"), ("TJ", "Tayikistán"),
    ("IO", "Territorio Británico del Océano Índico"),
    ("TF", "Territorios Australes Franceses"), ("TL", "Timor Oriental"),
    ("TG", "Togo"), ("TK", "Tokelau"), ("TO", "Tonga"), ("TT", "Trinidad y Tobago"),
    ("TN", "Túnez"), ("TM", "Turkmenistán"), ("TR", "Turquía"), ("TV", "Tuvalu"),
    ("UA", "Ucrania"), ("UG", "Uganda"), ("UY", "Uruguay"), ("UZ", "Uzbekistán"),
    ("VU", "Vanuatu"), ("VE", "Venezuela"), ("VN", "Vietnam"), ("WF", "Wallis y Futuna"),
    ("YE", "Yemen"), ("DJ", "Yibuti"), ("ZM", "Zambia"), ("ZW", "Zimbabue"),
]

names = [n for _, n in paises]
codes = [c for c, _ in paises]
assert not [n for n, c in Counter(names).items() if c > 1], "nombres duplicados"
assert not [c for c, x in Counter(codes).items() if x > 1], "códigos duplicados"

lines = [
    f"  ('{n.replace(chr(39), chr(39)+chr(39))}', '{c}')"
    for c, n in sorted(paises, key=lambda x: x[1].casefold())
]

header = '''-- Seed + endurecimiento de public.nacionalidad (Auth escalable).
-- Idempotente: se puede reaplicar con db push / migrate.
-- Catálogo: ISO 3166-1 alpha-2 con nombre en español (UX LatAm / HAKU).
-- No editar migraciones ya aplicadas; cambios futuros = archivo nuevo.

-- 0) Limpieza defensiva si el VPS ya tenía códigos duplicados.
DELETE FROM public.nacionalidad a
USING public.nacionalidad b
WHERE a.codigo_iso IS NOT NULL
  AND b.codigo_iso IS NOT NULL
  AND lower(a.codigo_iso) = lower(b.codigo_iso)
  AND a.id > b.id;

-- 1) Clave natural estable para upserts futuros (apps, sync, Google OAuth).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'nacionalidad_codigo_iso_key'
      AND conrelid = 'public.nacionalidad'::regclass
  ) THEN
    ALTER TABLE public.nacionalidad
      ADD CONSTRAINT nacionalidad_codigo_iso_key UNIQUE (codigo_iso);
  END IF;
END $$;

-- 2) Índices de lectura (picker / búsqueda).
CREATE INDEX IF NOT EXISTS idx_nacionalidad_nombre_lower
  ON public.nacionalidad (lower(nombre));

CREATE INDEX IF NOT EXISTS idx_nacionalidad_codigo_iso
  ON public.nacionalidad (codigo_iso);

-- 3) Alinear nombres de códigos ya existentes.
UPDATE public.nacionalidad AS n
SET nombre = v.nombre
FROM (
  VALUES
'''

mid = '''
) AS v(nombre, codigo_iso)
WHERE n.codigo_iso = v.codigo_iso
  AND n.nombre IS DISTINCT FROM v.nombre;

-- 4) Insertar solo códigos que aún no existen (respeta UNIQUE nombre si hubo seed parcial).
INSERT INTO public.nacionalidad (nombre, codigo_iso)
SELECT v.nombre, v.codigo_iso
FROM (
  VALUES
'''

footer = '''
) AS v(nombre, codigo_iso)
WHERE NOT EXISTS (
  SELECT 1 FROM public.nacionalidad n WHERE n.codigo_iso = v.codigo_iso
)
AND NOT EXISTS (
  SELECT 1 FROM public.nacionalidad n WHERE n.nombre = v.nombre
);

-- 5) Fallback del trigger: PE (HAKU) → cualquier fila → error claro.
CREATE OR REPLACE FUNCTION public.handle_new_user()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
declare
  v_nick text;
  v_nombres text;
  v_apellidos text;
  v_nacionalidad_id integer;
begin
  v_nick := nullif(trim(coalesce(new.raw_user_meta_data->>'nombre_nick', '')), '');
  if v_nick is null then
    v_nick := split_part(coalesce(new.email, 'usuario'), '@', 1);
  end if;
  v_nick := left(v_nick, 50);

  v_nombres := nullif(trim(coalesce(new.raw_user_meta_data->>'nombres', '')), '');
  if v_nombres is null then
    v_nombres := v_nick;
  end if;
  v_nombres := left(v_nombres, 100);

  v_apellidos := nullif(trim(coalesce(new.raw_user_meta_data->>'apellidos', '')), '');
  if v_apellidos is null then
    v_apellidos := 'N/D';
  end if;
  v_apellidos := left(v_apellidos, 100);

  begin
    v_nacionalidad_id := nullif(trim(coalesce(new.raw_user_meta_data->>'nacionalidad_id', '')), '')::integer;
  exception
    when others then
      v_nacionalidad_id := null;
  end;

  if v_nacionalidad_id is null
     or not exists (select 1 from public.nacionalidad n where n.id = v_nacionalidad_id) then
    select n.id into v_nacionalidad_id
    from public.nacionalidad n
    where n.codigo_iso = 'PE'
    limit 1;
  end if;

  if v_nacionalidad_id is null then
    select n.id into v_nacionalidad_id
    from public.nacionalidad n
    order by n.nombre
    limit 1;
  end if;

  if v_nacionalidad_id is null then
    raise exception
      'Catálogo public.nacionalidad vacío. Aplica la migración de seed de nacionalidades.';
  end if;

  insert into public.usuario (
    id,
    nombres,
    apellidos,
    nombre_nick,
    correo,
    foto_perfil,
    estado,
    nacionalidad_id
  ) values (
    new.id,
    v_nombres,
    v_apellidos,
    v_nick,
    coalesce(new.email, ''),
    nullif(trim(coalesce(new.raw_user_meta_data->>'avatar_url', '')), ''),
    'activo',
    v_nacionalidad_id
  );

  return new;
end;
$function$;

COMMENT ON TABLE public.nacionalidad IS
  'Catálogo ISO 3166-1 (codigo_iso). Fuente de verdad para registro/Auth; clientes deben preferir codigo_iso, no hardcodear IDs.';

COMMENT ON COLUMN public.nacionalidad.codigo_iso IS
  'ISO 3166-1 alpha-2. Clave natural para upserts y fallback (p. ej. PE).';
'''

out = Path(__file__).resolve().parent / "20260911040000_seed_nacionalidades_iso.sql"
values = ",\n".join(lines)
out.write_text(header + values + mid + values + footer, encoding="utf-8")
print(f"Wrote {out} ({len(paises)} countries)")
