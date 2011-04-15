#--
# Copyright (c) 2009 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

RubyPackager::ReleaseInfo.new.
  author(
    :Name => 'Muriel Salvan',
    :EMail => 'murielsalvan@users.sourceforge.net',
    :WebPageURL => 'http://murielsalvan.users.sourceforge.net'
  ).
  project(
    :Name => 'MusicMaster',
    :WebPageURL => 'http://musicmaster.sourceforge.net/',
    :Summary => 'Command line tool helping recording, mixing and mastering music tracks and albums.',
    :Description => 'Command line tool handling steps to deliver music album masters from recordings. Handle Track Mixing, Track Mastering, Track Master Delivery, Album Mastering and Album Master Delivery. Easy-to-use configuration files drive the complete processes.',
    :ImageURL => 'http://musicmaster.sourceforge.net/wiki/images/d/d4/Logo.jpg',
    :FaviconURL => 'http://musicmaster.sourceforge.net/wiki/images/2/26/Favicon.png',
    :SVNBrowseURL => 'http://musicmaster.svn.sourceforge.net/viewvc/musicmaster/',
    :DevStatus => 'Alpha'
  ).
  addCoreFiles( [
    '{lib,bin}/**/*'
  ] ).
#  addTestFiles( [
#    'test/**/*'
#  ] ).
  addAdditionalFiles( [
    'README',
    'LICENSE',
    'AUTHORS',
    'Credits',
    'TODO',
    'ChangeLog',
    '*.example'
  ] ).
  gem(
    :GemName => 'MusicMaster',
    :GemPlatformClassName => 'Gem::Platform::RUBY',
    :RequirePath => 'lib',
    :HasRDoc => true,
#    :TestFile => 'test/run.rb',
    :GemDependencies => [
      [ 'WaveSwissKnife', '>= 0.0.1' ]
    ]
  ).
  sourceForge(
    :Login => 'murielsalvan',
    :ProjectUnixName => 'musicmaster'
  ).
  rubyForge(
    :ProjectUnixName => 'musicmaster'
  ).
  executable(
    :StartupRBFile => 'bin/Album.rb'
  ).
  executable(
    :StartupRBFile => 'bin/AnalyzeAlbum.rb'
  ).
  executable(
    :StartupRBFile => 'bin/DBConvert.rb'
  ).
  executable(
    :StartupRBFile => 'bin/Deliver.rb'
  ).
  executable(
    :StartupRBFile => 'bin/DeliverAlbum.rb'
  ).
  executable(
    :StartupRBFile => 'bin/Fct2Wave.rb'
  ).
  executable(
    :StartupRBFile => 'bin/Master.rb'
  ).
  executable(
    :StartupRBFile => 'bin/Mix.rb'
  ).
  executable(
    :StartupRBFile => 'bin/PrepareMix.rb'
  ).
  executable(
    :StartupRBFile => 'bin/Record.rb'
  )

