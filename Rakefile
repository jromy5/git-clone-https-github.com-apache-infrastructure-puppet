require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'

PuppetSyntax.exclude_paths = ['3rdParty/**/*', 'modules/_TEMPLATE/**/*']
PuppetSyntax.hieradata_paths = ['data/**/*.yaml', 'data/**/*.eyaml', 'hiera.yaml']

Rake::Task[:lint].clear
PuppetLint::RakeTask.new :lint do |config|
  config.ignore_paths = ['3rdParty/**/*.pp']
  config.fail_on_warnings = true
  # TODO: decide if ignoring these are appropriate
  config.disable_checks = [
    '80chars',
    'class_inherits_from_params_class',
    'class_parameter_defaults',
    'documentation',
    'variable_scope',
  ]
end
