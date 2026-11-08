enum ViewState {
  loading, // Cargando desde Supabase
  success, // Datos recibidos con éxito
  empty,   // Lista vacía (0 registros)
  error,   // Fallo de red o servidor (habilita botón Reintentar)
}