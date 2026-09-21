-- Corrección del trigger de inscripción en salidas.
-- El trigger anterior solo actuaba en INSERT.
-- Si un usuario cancelaba su participación y luego volvía a unirse,
-- esto generaba un UPDATE que evadía el bloqueo de inscripciones cerradas.

DROP TRIGGER IF EXISTS trg_salida_participante_check_abierta ON public.salida_participante;

CREATE TRIGGER trg_salida_participante_check_abierta
  BEFORE INSERT OR UPDATE OF estado ON public.salida_participante
  FOR EACH ROW
  -- Solo evaluar si el estado va a ser 'confirmado'
  WHEN (NEW.estado = 'confirmado')
  EXECUTE FUNCTION public.func_salida_participante_check_abierta();
