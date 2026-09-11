-- Seed + endurecimiento de public.nacionalidad (Auth escalable).
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
  ('Afganistán', 'AF'),
  ('Albania', 'AL'),
  ('Alemania', 'DE'),
  ('Andorra', 'AD'),
  ('Angola', 'AO'),
  ('Anguila', 'AI'),
  ('Antigua y Barbuda', 'AG'),
  ('Antártida', 'AQ'),
  ('Arabia Saudita', 'SA'),
  ('Argelia', 'DZ'),
  ('Argentina', 'AR'),
  ('Armenia', 'AM'),
  ('Aruba', 'AW'),
  ('Australia', 'AU'),
  ('Austria', 'AT'),
  ('Azerbaiyán', 'AZ'),
  ('Bahamas', 'BS'),
  ('Bangladés', 'BD'),
  ('Barbados', 'BB'),
  ('Baréin', 'BH'),
  ('Belice', 'BZ'),
  ('Benín', 'BJ'),
  ('Bermudas', 'BM'),
  ('Bielorrusia', 'BY'),
  ('Bolivia', 'BO'),
  ('Bosnia y Herzegovina', 'BA'),
  ('Botsuana', 'BW'),
  ('Brasil', 'BR'),
  ('Brunéi', 'BN'),
  ('Bulgaria', 'BG'),
  ('Burkina Faso', 'BF'),
  ('Burundi', 'BI'),
  ('Bután', 'BT'),
  ('Bélgica', 'BE'),
  ('Cabo Verde', 'CV'),
  ('Camboya', 'KH'),
  ('Camerún', 'CM'),
  ('Canadá', 'CA'),
  ('Catar', 'QA'),
  ('Chad', 'TD'),
  ('Chequia', 'CZ'),
  ('Chile', 'CL'),
  ('China', 'CN'),
  ('Chipre', 'CY'),
  ('Ciudad del Vaticano', 'VA'),
  ('Colombia', 'CO'),
  ('Comoras', 'KM'),
  ('Congo', 'CG'),
  ('Congo (R.D.)', 'CD'),
  ('Corea del Norte', 'KP'),
  ('Corea del Sur', 'KR'),
  ('Costa de Marfil', 'CI'),
  ('Costa Rica', 'CR'),
  ('Croacia', 'HR'),
  ('Cuba', 'CU'),
  ('Curazao', 'CW'),
  ('Dinamarca', 'DK'),
  ('Dominica', 'DM'),
  ('Ecuador', 'EC'),
  ('Egipto', 'EG'),
  ('El Salvador', 'SV'),
  ('Emiratos Árabes Unidos', 'AE'),
  ('Eritrea', 'ER'),
  ('Eslovaquia', 'SK'),
  ('Eslovenia', 'SI'),
  ('España', 'ES'),
  ('Estados Unidos', 'US'),
  ('Estonia', 'EE'),
  ('Esuatini', 'SZ'),
  ('Etiopía', 'ET'),
  ('Filipinas', 'PH'),
  ('Finlandia', 'FI'),
  ('Fiyi', 'FJ'),
  ('Francia', 'FR'),
  ('Gabón', 'GA'),
  ('Gambia', 'GM'),
  ('Georgia', 'GE'),
  ('Ghana', 'GH'),
  ('Gibraltar', 'GI'),
  ('Granada', 'GD'),
  ('Grecia', 'GR'),
  ('Groenlandia', 'GL'),
  ('Guadalupe', 'GP'),
  ('Guam', 'GU'),
  ('Guatemala', 'GT'),
  ('Guayana Francesa', 'GF'),
  ('Guernsey', 'GG'),
  ('Guinea', 'GN'),
  ('Guinea Ecuatorial', 'GQ'),
  ('Guinea-Bisáu', 'GW'),
  ('Guyana', 'GY'),
  ('Haití', 'HT'),
  ('Honduras', 'HN'),
  ('Hong Kong', 'HK'),
  ('Hungría', 'HU'),
  ('India', 'IN'),
  ('Indonesia', 'ID'),
  ('Irak', 'IQ'),
  ('Irlanda', 'IE'),
  ('Irán', 'IR'),
  ('Isla Bouvet', 'BV'),
  ('Isla de Man', 'IM'),
  ('Isla de Navidad', 'CX'),
  ('Isla Norfolk', 'NF'),
  ('Islandia', 'IS'),
  ('Islas Caimán', 'KY'),
  ('Islas Cook', 'CK'),
  ('Islas Feroe', 'FO'),
  ('Islas Georgias del Sur', 'GS'),
  ('Islas Heard y McDonald', 'HM'),
  ('Islas Malvinas', 'FK'),
  ('Islas Marianas del Norte', 'MP'),
  ('Islas Marshall', 'MH'),
  ('Islas Pitcairn', 'PN'),
  ('Islas Salomón', 'SB'),
  ('Islas Turcas y Caicos', 'TC'),
  ('Islas Ultramarinas de EE.UU.', 'UM'),
  ('Islas Vírgenes Británicas', 'VG'),
  ('Islas Vírgenes de EE.UU.', 'VI'),
  ('Islas Åland', 'AX'),
  ('Israel', 'IL'),
  ('Italia', 'IT'),
  ('Jamaica', 'JM'),
  ('Japón', 'JP'),
  ('Jersey', 'JE'),
  ('Jordania', 'JO'),
  ('Kazajistán', 'KZ'),
  ('Kenia', 'KE'),
  ('Kirguistán', 'KG'),
  ('Kiribati', 'KI'),
  ('Kuwait', 'KW'),
  ('Laos', 'LA'),
  ('Lesoto', 'LS'),
  ('Letonia', 'LV'),
  ('Liberia', 'LR'),
  ('Libia', 'LY'),
  ('Liechtenstein', 'LI'),
  ('Lituania', 'LT'),
  ('Luxemburgo', 'LU'),
  ('Líbano', 'LB'),
  ('Macao', 'MO'),
  ('Macedonia del Norte', 'MK'),
  ('Madagascar', 'MG'),
  ('Malasia', 'MY'),
  ('Malaui', 'MW'),
  ('Maldivas', 'MV'),
  ('Malta', 'MT'),
  ('Malí', 'ML'),
  ('Marruecos', 'MA'),
  ('Martinica', 'MQ'),
  ('Mauricio', 'MU'),
  ('Mauritania', 'MR'),
  ('Mayotte', 'YT'),
  ('Micronesia', 'FM'),
  ('Moldavia', 'MD'),
  ('Mongolia', 'MN'),
  ('Montenegro', 'ME'),
  ('Montserrat', 'MS'),
  ('Mozambique', 'MZ'),
  ('Myanmar', 'MM'),
  ('México', 'MX'),
  ('Mónaco', 'MC'),
  ('Namibia', 'NA'),
  ('Nauru', 'NR'),
  ('Nepal', 'NP'),
  ('Nicaragua', 'NI'),
  ('Nigeria', 'NG'),
  ('Niue', 'NU'),
  ('Noruega', 'NO'),
  ('Nueva Caledonia', 'NC'),
  ('Nueva Zelanda', 'NZ'),
  ('Níger', 'NE'),
  ('Omán', 'OM'),
  ('Pakistán', 'PK'),
  ('Palaos', 'PW'),
  ('Palestina', 'PS'),
  ('Panamá', 'PA'),
  ('Papúa Nueva Guinea', 'PG'),
  ('Paraguay', 'PY'),
  ('Países Bajos', 'NL'),
  ('Perú', 'PE'),
  ('Polinesia Francesa', 'PF'),
  ('Polonia', 'PL'),
  ('Portugal', 'PT'),
  ('Puerto Rico', 'PR'),
  ('Reino Unido', 'GB'),
  ('República Centroafricana', 'CF'),
  ('República Dominicana', 'DO'),
  ('Reunión', 'RE'),
  ('Ruanda', 'RW'),
  ('Rumania', 'RO'),
  ('Rusia', 'RU'),
  ('Samoa', 'WS'),
  ('Samoa Americana', 'AS'),
  ('San Bartolomé', 'BL'),
  ('San Cristóbal y Nieves', 'KN'),
  ('San Marino', 'SM'),
  ('San Martín (Francia)', 'MF'),
  ('San Pedro y Miquelón', 'PM'),
  ('San Vicente y las Granadinas', 'VC'),
  ('Santa Elena', 'SH'),
  ('Santa Lucía', 'LC'),
  ('Santo Tomé y Príncipe', 'ST'),
  ('Senegal', 'SN'),
  ('Serbia', 'RS'),
  ('Seychelles', 'SC'),
  ('Sierra Leona', 'SL'),
  ('Singapur', 'SG'),
  ('Sint Maarten', 'SX'),
  ('Siria', 'SY'),
  ('Somalia', 'SO'),
  ('Sri Lanka', 'LK'),
  ('Sudáfrica', 'ZA'),
  ('Sudán', 'SD'),
  ('Sudán del Sur', 'SS'),
  ('Suecia', 'SE'),
  ('Suiza', 'CH'),
  ('Surinam', 'SR'),
  ('Svalbard y Jan Mayen', 'SJ'),
  ('Sáhara Occidental', 'EH'),
  ('Tailandia', 'TH'),
  ('Taiwán', 'TW'),
  ('Tanzania', 'TZ'),
  ('Tayikistán', 'TJ'),
  ('Territorio Británico del Océano Índico', 'IO'),
  ('Territorios Australes Franceses', 'TF'),
  ('Timor Oriental', 'TL'),
  ('Togo', 'TG'),
  ('Tokelau', 'TK'),
  ('Tonga', 'TO'),
  ('Trinidad y Tobago', 'TT'),
  ('Turkmenistán', 'TM'),
  ('Turquía', 'TR'),
  ('Tuvalu', 'TV'),
  ('Túnez', 'TN'),
  ('Ucrania', 'UA'),
  ('Uganda', 'UG'),
  ('Uruguay', 'UY'),
  ('Uzbekistán', 'UZ'),
  ('Vanuatu', 'VU'),
  ('Venezuela', 'VE'),
  ('Vietnam', 'VN'),
  ('Wallis y Futuna', 'WF'),
  ('Yemen', 'YE'),
  ('Yibuti', 'DJ'),
  ('Zambia', 'ZM'),
  ('Zimbabue', 'ZW')
) AS v(nombre, codigo_iso)
WHERE n.codigo_iso = v.codigo_iso
  AND n.nombre IS DISTINCT FROM v.nombre;

-- 4) Insertar solo códigos que aún no existen (respeta UNIQUE nombre si hubo seed parcial).
INSERT INTO public.nacionalidad (nombre, codigo_iso)
SELECT v.nombre, v.codigo_iso
FROM (
  VALUES
  ('Afganistán', 'AF'),
  ('Albania', 'AL'),
  ('Alemania', 'DE'),
  ('Andorra', 'AD'),
  ('Angola', 'AO'),
  ('Anguila', 'AI'),
  ('Antigua y Barbuda', 'AG'),
  ('Antártida', 'AQ'),
  ('Arabia Saudita', 'SA'),
  ('Argelia', 'DZ'),
  ('Argentina', 'AR'),
  ('Armenia', 'AM'),
  ('Aruba', 'AW'),
  ('Australia', 'AU'),
  ('Austria', 'AT'),
  ('Azerbaiyán', 'AZ'),
  ('Bahamas', 'BS'),
  ('Bangladés', 'BD'),
  ('Barbados', 'BB'),
  ('Baréin', 'BH'),
  ('Belice', 'BZ'),
  ('Benín', 'BJ'),
  ('Bermudas', 'BM'),
  ('Bielorrusia', 'BY'),
  ('Bolivia', 'BO'),
  ('Bosnia y Herzegovina', 'BA'),
  ('Botsuana', 'BW'),
  ('Brasil', 'BR'),
  ('Brunéi', 'BN'),
  ('Bulgaria', 'BG'),
  ('Burkina Faso', 'BF'),
  ('Burundi', 'BI'),
  ('Bután', 'BT'),
  ('Bélgica', 'BE'),
  ('Cabo Verde', 'CV'),
  ('Camboya', 'KH'),
  ('Camerún', 'CM'),
  ('Canadá', 'CA'),
  ('Catar', 'QA'),
  ('Chad', 'TD'),
  ('Chequia', 'CZ'),
  ('Chile', 'CL'),
  ('China', 'CN'),
  ('Chipre', 'CY'),
  ('Ciudad del Vaticano', 'VA'),
  ('Colombia', 'CO'),
  ('Comoras', 'KM'),
  ('Congo', 'CG'),
  ('Congo (R.D.)', 'CD'),
  ('Corea del Norte', 'KP'),
  ('Corea del Sur', 'KR'),
  ('Costa de Marfil', 'CI'),
  ('Costa Rica', 'CR'),
  ('Croacia', 'HR'),
  ('Cuba', 'CU'),
  ('Curazao', 'CW'),
  ('Dinamarca', 'DK'),
  ('Dominica', 'DM'),
  ('Ecuador', 'EC'),
  ('Egipto', 'EG'),
  ('El Salvador', 'SV'),
  ('Emiratos Árabes Unidos', 'AE'),
  ('Eritrea', 'ER'),
  ('Eslovaquia', 'SK'),
  ('Eslovenia', 'SI'),
  ('España', 'ES'),
  ('Estados Unidos', 'US'),
  ('Estonia', 'EE'),
  ('Esuatini', 'SZ'),
  ('Etiopía', 'ET'),
  ('Filipinas', 'PH'),
  ('Finlandia', 'FI'),
  ('Fiyi', 'FJ'),
  ('Francia', 'FR'),
  ('Gabón', 'GA'),
  ('Gambia', 'GM'),
  ('Georgia', 'GE'),
  ('Ghana', 'GH'),
  ('Gibraltar', 'GI'),
  ('Granada', 'GD'),
  ('Grecia', 'GR'),
  ('Groenlandia', 'GL'),
  ('Guadalupe', 'GP'),
  ('Guam', 'GU'),
  ('Guatemala', 'GT'),
  ('Guayana Francesa', 'GF'),
  ('Guernsey', 'GG'),
  ('Guinea', 'GN'),
  ('Guinea Ecuatorial', 'GQ'),
  ('Guinea-Bisáu', 'GW'),
  ('Guyana', 'GY'),
  ('Haití', 'HT'),
  ('Honduras', 'HN'),
  ('Hong Kong', 'HK'),
  ('Hungría', 'HU'),
  ('India', 'IN'),
  ('Indonesia', 'ID'),
  ('Irak', 'IQ'),
  ('Irlanda', 'IE'),
  ('Irán', 'IR'),
  ('Isla Bouvet', 'BV'),
  ('Isla de Man', 'IM'),
  ('Isla de Navidad', 'CX'),
  ('Isla Norfolk', 'NF'),
  ('Islandia', 'IS'),
  ('Islas Caimán', 'KY'),
  ('Islas Cook', 'CK'),
  ('Islas Feroe', 'FO'),
  ('Islas Georgias del Sur', 'GS'),
  ('Islas Heard y McDonald', 'HM'),
  ('Islas Malvinas', 'FK'),
  ('Islas Marianas del Norte', 'MP'),
  ('Islas Marshall', 'MH'),
  ('Islas Pitcairn', 'PN'),
  ('Islas Salomón', 'SB'),
  ('Islas Turcas y Caicos', 'TC'),
  ('Islas Ultramarinas de EE.UU.', 'UM'),
  ('Islas Vírgenes Británicas', 'VG'),
  ('Islas Vírgenes de EE.UU.', 'VI'),
  ('Islas Åland', 'AX'),
  ('Israel', 'IL'),
  ('Italia', 'IT'),
  ('Jamaica', 'JM'),
  ('Japón', 'JP'),
  ('Jersey', 'JE'),
  ('Jordania', 'JO'),
  ('Kazajistán', 'KZ'),
  ('Kenia', 'KE'),
  ('Kirguistán', 'KG'),
  ('Kiribati', 'KI'),
  ('Kuwait', 'KW'),
  ('Laos', 'LA'),
  ('Lesoto', 'LS'),
  ('Letonia', 'LV'),
  ('Liberia', 'LR'),
  ('Libia', 'LY'),
  ('Liechtenstein', 'LI'),
  ('Lituania', 'LT'),
  ('Luxemburgo', 'LU'),
  ('Líbano', 'LB'),
  ('Macao', 'MO'),
  ('Macedonia del Norte', 'MK'),
  ('Madagascar', 'MG'),
  ('Malasia', 'MY'),
  ('Malaui', 'MW'),
  ('Maldivas', 'MV'),
  ('Malta', 'MT'),
  ('Malí', 'ML'),
  ('Marruecos', 'MA'),
  ('Martinica', 'MQ'),
  ('Mauricio', 'MU'),
  ('Mauritania', 'MR'),
  ('Mayotte', 'YT'),
  ('Micronesia', 'FM'),
  ('Moldavia', 'MD'),
  ('Mongolia', 'MN'),
  ('Montenegro', 'ME'),
  ('Montserrat', 'MS'),
  ('Mozambique', 'MZ'),
  ('Myanmar', 'MM'),
  ('México', 'MX'),
  ('Mónaco', 'MC'),
  ('Namibia', 'NA'),
  ('Nauru', 'NR'),
  ('Nepal', 'NP'),
  ('Nicaragua', 'NI'),
  ('Nigeria', 'NG'),
  ('Niue', 'NU'),
  ('Noruega', 'NO'),
  ('Nueva Caledonia', 'NC'),
  ('Nueva Zelanda', 'NZ'),
  ('Níger', 'NE'),
  ('Omán', 'OM'),
  ('Pakistán', 'PK'),
  ('Palaos', 'PW'),
  ('Palestina', 'PS'),
  ('Panamá', 'PA'),
  ('Papúa Nueva Guinea', 'PG'),
  ('Paraguay', 'PY'),
  ('Países Bajos', 'NL'),
  ('Perú', 'PE'),
  ('Polinesia Francesa', 'PF'),
  ('Polonia', 'PL'),
  ('Portugal', 'PT'),
  ('Puerto Rico', 'PR'),
  ('Reino Unido', 'GB'),
  ('República Centroafricana', 'CF'),
  ('República Dominicana', 'DO'),
  ('Reunión', 'RE'),
  ('Ruanda', 'RW'),
  ('Rumania', 'RO'),
  ('Rusia', 'RU'),
  ('Samoa', 'WS'),
  ('Samoa Americana', 'AS'),
  ('San Bartolomé', 'BL'),
  ('San Cristóbal y Nieves', 'KN'),
  ('San Marino', 'SM'),
  ('San Martín (Francia)', 'MF'),
  ('San Pedro y Miquelón', 'PM'),
  ('San Vicente y las Granadinas', 'VC'),
  ('Santa Elena', 'SH'),
  ('Santa Lucía', 'LC'),
  ('Santo Tomé y Príncipe', 'ST'),
  ('Senegal', 'SN'),
  ('Serbia', 'RS'),
  ('Seychelles', 'SC'),
  ('Sierra Leona', 'SL'),
  ('Singapur', 'SG'),
  ('Sint Maarten', 'SX'),
  ('Siria', 'SY'),
  ('Somalia', 'SO'),
  ('Sri Lanka', 'LK'),
  ('Sudáfrica', 'ZA'),
  ('Sudán', 'SD'),
  ('Sudán del Sur', 'SS'),
  ('Suecia', 'SE'),
  ('Suiza', 'CH'),
  ('Surinam', 'SR'),
  ('Svalbard y Jan Mayen', 'SJ'),
  ('Sáhara Occidental', 'EH'),
  ('Tailandia', 'TH'),
  ('Taiwán', 'TW'),
  ('Tanzania', 'TZ'),
  ('Tayikistán', 'TJ'),
  ('Territorio Británico del Océano Índico', 'IO'),
  ('Territorios Australes Franceses', 'TF'),
  ('Timor Oriental', 'TL'),
  ('Togo', 'TG'),
  ('Tokelau', 'TK'),
  ('Tonga', 'TO'),
  ('Trinidad y Tobago', 'TT'),
  ('Turkmenistán', 'TM'),
  ('Turquía', 'TR'),
  ('Tuvalu', 'TV'),
  ('Túnez', 'TN'),
  ('Ucrania', 'UA'),
  ('Uganda', 'UG'),
  ('Uruguay', 'UY'),
  ('Uzbekistán', 'UZ'),
  ('Vanuatu', 'VU'),
  ('Venezuela', 'VE'),
  ('Vietnam', 'VN'),
  ('Wallis y Futuna', 'WF'),
  ('Yemen', 'YE'),
  ('Yibuti', 'DJ'),
  ('Zambia', 'ZM'),
  ('Zimbabue', 'ZW')
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
