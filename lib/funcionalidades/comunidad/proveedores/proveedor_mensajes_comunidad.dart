import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/proveedores/proveedor_chat.dart';

export '../../chat/proveedores/proveedor_chat.dart'
    show
        chatDataSourceProvider,
        chatVersionProvider,
        mensajesSalaProvider,
        previewsChatComunidadProvider,
        notificarChatCambio;

@Deprecated('Usá notificarChatCambio')
void notificarMensajesComunidadCambiaron(WidgetRef ref) {
  notificarChatCambio(ref);
}
