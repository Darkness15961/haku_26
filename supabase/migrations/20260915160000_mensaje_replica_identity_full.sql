-- Endurece Realtime de chat: UPDATE de mensaje filtrable por sala_id.
-- Append-only. Sin eso, edit/soft-delete no llegan a otros clientes.

ALTER TABLE public.mensaje REPLICA IDENTITY FULL;

-- DELETE de reacción necesita old row con mensaje_id para el cliente.
ALTER TABLE public.mensaje_reaccion REPLICA IDENTITY FULL;

COMMENT ON TABLE public.mensaje IS
  'REPLICA IDENTITY FULL: Realtime UPDATE filtrado por sala_id (edit/soft-delete).';
