class RateLimitController < ApplicationController
  skip_before_action :authenticate_user!
  
  def check_login
    email = params[:email].to_s.downcase.strip
    
    if email.blank?
      render json: { blocked: false }
      return
    end
    
    # Período de 10 minutos = 600 segundos
    period = 600
    
    # IMPORTANTE: Usar la MISMA discriminator que Rack-Attack
    # Rack-Attack usa: req.params.dig("user", "login")
    # Nosotros recibimos el email directo, así que lo usamos
    discriminator = email
    
    # Construir la key EXACTAMENTE como Rack-Attack
    # Formato: "rack::attack:{period_number}:logins/email:{discriminator}"
    period_number = Time.current.to_i / period
    throttle_key = "logins/email:#{discriminator}"
    cache_key = "rack::attack:#{period_number}:#{throttle_key}"
    
    # Leer contador
    count = Rack::Attack.cache.read(cache_key).to_i
    
    Rails.logger.info "=== RATE LIMIT CHECK ==="
    Rails.logger.info "Email: #{email}"
    Rails.logger.info "Cache Key: #{cache_key}"
    Rails.logger.info "Count: #{count}/5"
    Rails.logger.info "========================"
    
    if count >= 5
      # Bloqueado
      period_end = (period_number + 1) * period
      retry_after = period_end - Time.current.to_i
      
      render json: {
        blocked: true,
        retry_after: retry_after,
        attempts: count,
        limit: 5
      }
    else
      # OK
      render json: {
        blocked: false,
        attempts: count,
        remaining: 5 - count
      }
    end
  end
end