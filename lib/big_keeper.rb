#!/usr/bin/env ruby

require './big_keeper/version'

require './big_keeper/util/bigkeeper_parser'
require './big_keeper/util/git_operator'

require './big_keeper/model/gitflow_type'

require './big_keeper/command/feature_start'
require './big_keeper/command/feature_finish'
require './big_keeper/command/feature_pull'
require './big_keeper/command/feature_push'
require './big_keeper/command/start_home_release'
require './big_keeper/command/start_module_release'

require './big_keeper/service/git_service'

require 'gli'

include GLI::App

module BigKeeper

  # Your code goes here...
  program_desc 'Efficiency improvement for iOS modular development, iOSer using this tool can make modular development easier.'

  flag %i[p path], default_value: './'
  flag %i[v version], default_value: 'Version in Bigkeeper file'
  path, version = ''
  pre do |global_options, _command, options, args|
    path = File.expand_path(global_options[:path])
    version = global_options[:version]
  end

  desc 'Feature operations'
  command :feature do |c|

    c.flag %i[u user], default_value: GitOperator.new.user
    user = GitOperator.new.user
    c.pre do |global_options, _command, options, args|
      user = global_options[:user]
    end

    c.desc 'Start a new feature with name for given modules and main project'
    c.command :start do |start|
      start.action do |global_options, options, args|
        help_now!('feature name is required') if args.length < 1
        name = args[0]
        modules = args[(1...args.length)] if args.length > 1
        feature_start(path, version, user, name, modules)
      end
    end

    c.desc 'Switch to the feature with name'
    c.command :switch do |switch|
      switch.action do |global_options, options, args|
      end
    end

    c.desc 'Pull remote changes for current feature'
    c.command :pull do |pull|
      pull.action do |global_options, options, args|
        feature_pull(path, user, name)
      end
    end

    c.desc 'Push local changes to remote for current feature'
    c.command :push do |push|
      push.flag %i[m comment], default_value: ''

      comment = ''
      push.pre do |global_options, _command, options, args|
        comment = global_options[:comment]
      end

      push.action do |global_options, options, args|
        p comment
        feature_push(path, user, name, comment)
      end
    end

    c.desc 'Finish current feature'
    c.command :finish do |finish|
      finish.action do |global_options, options, args|
        feature_finish(path, user, name)
      end
    end

    c.desc 'List all the features'
    c.command :list do |list|
      list.action do
        branchs = GitService.new.branchs_with_type(File.expand_path(path), GitflowType::FEATURE)
        branchs.each do |branch|
          p branch
        end
      end
    end
  end

  desc 'Release operations'
  command :release do |c|
    c.desc 'Release home project operations'
    c.command :home do |home|
      home.desc 'Start release home project'
      home.command :start do |start|
        start.action do |global_options, options, args|
          # path(optional): path of the Bigkeeper file in project
          # version(optional): if null, will read verson in Bigkeeper file
          # e.g: ruby big_keeper.rb -p /Users/SFM/Downloads/BigKeeperMain-master
          # /Bigkeeper  -v 3.0.0 release home start
          start_home_release(path, version)
        end
      end

      home.desc 'Finish release home project'
      home.command :finish do |finish|
        finish.action do |global_options, options, args|
        end
      end

      home.desc 'Start release module'
      home.command :module do |finish|
        finish.action do |global_options, options, args|
          help_now!('module name is required') if args.length != 1
          module_name = args[0]
          start_module_release(path, module_name)
        end
      end
    end

  end

  exit run(ARGV)
end
