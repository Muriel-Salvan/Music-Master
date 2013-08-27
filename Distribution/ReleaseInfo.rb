RubyPackager::ReleaseInfo.new.
  author(
    :name => 'Muriel Salvan',
    :email => 'muriel@x-aeon.com',
    :web_page_url => 'http://murielsalvan.users.sourceforge.net'
  ).
  project(
    :name => 'MusicMaster',
    :web_page_url => 'http://musicmaster.sourceforge.net/',
    :summary => 'Command line tool helping recording, mixing and mastering music tracks and albums.',
    :description => 'Command line tool handling steps to deliver music album masters from recordings. Handle Track Mixing, Track Mastering, Track Master Delivery, Album Mastering and Album Master Delivery. Easy-to-use configuration files drive the complete processes.',
    :image_url => 'http://musicmaster.sourceforge.net/wiki/images/d/d4/Logo.jpg',
    :favicon_url => 'http://musicmaster.sourceforge.net/wiki/images/2/26/Favicon.png',
    :browse_source_url => 'http://github.com/Muriel-Salvan/Music-Master',
    :dev_status => 'Beta'
  ).
  add_core_files( [
    '{lib,bin}/**/*'
  ] ).
  add_test_files( [
    'test/**/*'
  ] ).
  add_additional_files( [
    'README',
    'LICENSE',
    'AUTHORS',
    'Credits',
    'ChangeLog',
    '*.example'
  ] ).
  gem(
    :gem_name => 'MusicMaster',
    :gem_platform_class_name => 'Gem::Platform::RUBY',
    :require_path => 'lib',
    :has_rdoc => true,
    :test_file => 'test/run.rb',
    :gem_dependencies => [
      # TODO: Use Rake 10 as soon as it behaves correctly
      [ 'rake', '~> 0.9' ],
      [ 'rUtilAnts', '>= 2.0' ],
      [ 'WaveSwissKnife', '>= 0.0.1' ]
    ]
  ).
  source_forge(
    :login => 'murielsalvan',
    :project_unix_name => 'musicmaster',
    :ask_for_key_passphrase => true
  ).
  ruby_forge(
    :project_unix_name => 'musicmaster'
  ).
#  executable(
#    :startup_rb_file => 'bin/Album.rb'
#  ).
#  executable(
#    :startup_rb_file => 'bin/AnalyzeAlbum.rb'
#  ).
  executable(
    :startup_rb_file => 'bin/Calibrate.rb'
  ).
  executable(
    :startup_rb_file => 'bin/Clean.rb'
  ).
  executable(
    :startup_rb_file => 'bin/DBConvert.rb'
  ).
  executable(
    :startup_rb_file => 'bin/Deliver.rb'
  ).
#  executable(
#    :startup_rb_file => 'bin/DeliverAlbum.rb'
#  ).
#  executable(
#    :startup_rb_file => 'bin/Fct2Wave.rb'
#  ).
  executable(
    :startup_rb_file => 'bin/Mix.rb'
  ).
  executable(
    :startup_rb_file => 'bin/Process.rb'
  ).
  executable(
    :startup_rb_file => 'bin/Record.rb'
  )
