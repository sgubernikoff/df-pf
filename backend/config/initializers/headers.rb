Rails.application.config.action_dispatch.default_headers.merge!({
  'Content-Security-Policy' => "frame-ancestors 'self' http://localhost:5173"
})
