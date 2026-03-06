# frozen_string_literal: true

target :lib do
  signature "sig"
  check "lib"

  library "logger"

  # ActiveRecord and ActiveSupport do not ship complete
  # RBS definitions. We provide minimal stubs in
  # sig/vendor/ for inheritance resolution, but many
  # dynamic methods (has_many, scope, where, etc.) are
  # unknown to Steep. We configure lenient checking so
  # that signature-vs-implementation alignment is
  # enforced while tolerating unresolvable Rails
  # dynamic dispatch.
  configure_code_diagnostics do |hash|
    # Ignore "does not have method" for AR dynamics
    hash[Steep::Diagnostic::Ruby::NoMethod] = :hint
    # Ignore "unknown constant" (e.g. Rails)
    hash[Steep::Diagnostic::Ruby::UnknownConstant] = :hint
    # Ignore undeclared method definitions from
    # module_function / dynamic dispatch
    hash[Steep::Diagnostic::Ruby::UndeclaredMethodDefinition] = :hint
    # Ignore block-given warnings from AR concern DSL
    hash[Steep::Diagnostic::Ruby::UnexpectedBlockGiven] = :hint
    # Ignore insufficient positional arguments from
    # AR concern `included` calls
    hash[Steep::Diagnostic::Ruby::InsufficientPositionalArguments] = :hint
  end
end
