# Automatically enable YJIT as of Ruby 3.3, as it brings very
# sizeable performance improvements.
#
# YJIT uses extra memory (~20–40MB). On memory-constrained hosts
# (e.g. Heroku Basic 512MB), leave RUBY_YJIT_ENABLE unset or "0".
# To enable: RUBY_YJIT_ENABLE=1
if defined?(RubyVM::YJIT.enable) && ENV["RUBY_YJIT_ENABLE"] == "1"
  Rails.application.config.after_initialize do
    RubyVM::YJIT.enable
  end
end
