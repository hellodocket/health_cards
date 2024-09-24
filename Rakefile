# frozen_string_literal: true

require 'rake/testtask'
require 'rake/task'
require 'minitest/test_task'

Minitest::TestTask.create(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.warning = false
  t.test_globs = ['test/**/*_test.rb']
end

task :test_app do
  system("cd test_app && ./test_health_cards_without_rails && cd ..")
end

desc 'Run tests'
task default: :test
