class Rack::Attack
  ### CONFIGURACIÓN GENERAL ###
  
  # Habilitar Rack::Attack
  Rack::Attack.enabled = true
  
  # Cache store (memoria en desarrollo, Redis en producción)
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  
  ### THROTTLING (LÍMITES DE VELOCIDAD) ###
  
  # 1. LOGINS FALLIDOS - 5 intentos cada 10 minutos por email
  throttle("logins/email", limit: 5, period: 10.minutes) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Obtener el email del request
      email = req.params.dig("user", "login") || req.params.dig("user", "email")
      
      # Solo contar si hay email
      # La key será el email (cada email tiene su propio contador)
      email if email
    end
  end
  
  # 2. REQUESTS GLOBALES - 200 requests por minuto por IP
  throttle("requests/ip", limit: 200, period: 1.minute) do |req|
    # La key es la IP (cada IP tiene su propio contador)
    req.ip
  end
  
  ### LOGGING (REGISTRAR BLOQUEOS) ###
  
  # Callback cuando se bloquea un request
  self.blocklisted_responder = lambda do |request|
    Rails.logger.warn "Rack-Attack: Request bloqueado"
    Rails.logger.warn "  IP: #{request.ip}"
    Rails.logger.warn "  Path: #{request.path}"
    Rails.logger.warn "  Email: #{request.params['email']}" if request.params["email"]
    Rails.logger.warn "  Time: #{Time.current}"
    
    # Respuesta al cliente
    [429, {}, ["Too Many Requests. Please try again later.\n"]]
  end
  
  # Callback cuando se alcanza el límite (throttle)
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = Time.current
    
    # Calcular tiempo de retry
    retry_after = match_data[:period] - (now.to_i % match_data[:period])
    
    Rails.logger.warn "Rack-Attack: Request throttled"
    Rails.logger.warn "  IP: #{request.ip}"
    Rails.logger.warn "  Path: #{request.path}"
    Rails.logger.warn "  Email: #{request.params['email']}" if request.params["email"]
    Rails.logger.warn "  Limit: #{match_data[:limit]}"
    Rails.logger.warn "  Period: #{match_data[:period]} seconds"
    Rails.logger.warn "  Retry after: #{retry_after} seconds"
    Rails.logger.warn "  Time: #{now}"
    
    # Respuesta al cliente con headers
    [
      429,
      {
        "Content-Type" => "text/plain",
        "Retry-After" => retry_after.to_s
      },
      ["Too Many Requests. Please try again in #{retry_after} seconds.\n"]
    ]
  end
end