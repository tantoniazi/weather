class Rack::Attack
  # Usar Redis para cache do rack-attack
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
    url: ENV.fetch("REDIS_URL") { "redis://redis:6379/0" },
  )

  # Rate limiting para API
  throttle("api/v1/weathers", limit: 60, period: 1.hour) do |req|
    if req.path.start_with?("/api/v1/weathers")
      req.ip
    end
  end

  # Rate limiting para busca de weather
  throttle("weather/search", limit: 30, period: 1.hour) do |req|
    if req.path == "/weathers/search" && req.get?
      req.ip
    end
  end

  # Rate limiting para export de relatórios
  throttle("reports/export", limit: 10, period: 1.hour) do |req|
    if req.path == "/reports/export" && req.post?
      req.ip
    end
  end

  # Rate limiting geral para requests
  throttle("requests by ip", limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  # Rate limiting para login
  throttle("login attempts", limit: 5, period: 20.minutes) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # Rate limiting para registro
  throttle("registration attempts", limit: 3, period: 1.hour) do |req|
    if req.path == "/users" && req.post?
      req.ip
    end
  end

  # Bloquear IPs maliciosos
  blocklist("block malicious IPs") do |req|
    # Lista de IPs bloqueados (pode ser carregada de um arquivo ou banco de dados)
    blocked_ips = []
    blocked_ips.include?(req.ip)
  end

  # Permitir IPs da lista branca
  safelist("allow from localhost") do |req|
    "127.0.0.1" == req.ip || "::1" == req.ip
  end

  # Customizar resposta para requests bloqueados
  self.throttled_response = lambda do |env|
    match_data = env["rack.attack.match_data"]
    now = match_data[:epoch_time]

    headers = {
      "RateLimit-Limit" => match_data[:limit].to_s,
      "RateLimit-Remaining" => "0",
      "RateLimit-Reset" => (now + (match_data[:period] - now % match_data[:period])).to_s,
      "Content-Type" => "application/json",
    }

    [429, headers, [{ error: "Rate limit exceeded. Try again later." }.to_json]]
  end
end

# Habilitar rack-attack
Rails.application.config.middleware.use Rack::Attack
