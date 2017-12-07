#!/usr/bin/ruby
require 'big_stash/stash_operator'

module BigKeeper
  def self.feature_switch(path, version, user, name)
    begin
      # Parse Bigkeeper file
      BigkeeperParser.parse("#{path}/Bigkeeper")

      version = BigkeeperParser.version if version == 'Version in Bigkeeper file'
      feature_name = "#{version}_#{user}_#{name}"
      branch_name = "#{GitflowType.name(GitflowType::FEATURE)}/#{feature_name}"

      GitService.new.verify_branch(path, branch_name, OperateType::SWITCH)

      stath_modules = PodfileOperator.new.modules_with_type("#{path}/Podfile",
                                BigkeeperParser.module_names, ModuleType::PATH)

      # Stash current branch
      StashService.new.stash(path, branch_name, user, stath_modules)

      # Switch to new feature
      GitOperator.new.git_checkout(path, branch_name)
      GitOperator.new.pull(path)

      # Apply home stash
      BigStash::StashOperator.new(path).pop_stash(branch_name)

      modules = PodfileOperator.new.modules_with_type("#{path}/Podfile",
                                BigkeeperParser.module_names, ModuleType::PATH)

      modules.each do |module_name|
        ModuleService.new.switch(path, user, module_name, branch_name)
      end

      # pod install
      p `pod install --project-directory=#{path}`

      # Open home workspace
      `open #{path}/*.xcworkspace`
    ensure
    end
  end
end
