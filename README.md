# Rototiller

A [Rake](https://github.com/ruby/rake) helper library for command-oriented tasks.

:warning: This version of Rototiller (master branch) is a work in progress!
It is already known that the API will change quite a bit for the next release. These API changes are underway.
Please see the notes at the top of the [Write](#write) section.

* simplifies the building of command strings in :rototiller_task for task authors
* abstracts the overriding of command string components: commands, flags, arguments for task users
* unifies and standardizes messaging surrounding the use of environment variables for task operations
* Provides a tool that can house shared rake task code for Puppet.
* Reduce duplication in Rakefiles across projects at Puppet.
* Reduce effort required to write first class rake tasks.
* Reduce time and effort trying to understand requirement to run rake tasks.
* Provide a standard interface for executing tests in a given test tier regardless of framework (Not MVP)

<a name="install"></a>
## Install
    gem install rototiller

<a name="write"></a>
## Write
Rototiller provides a Rake DSL addition called 'rototiller_task' which is a fully featured Rake task with environment variable handling, messaging and command-string-building functionality.

:warning: The API below will change for the next release.
The known changes include (not comprehensive):
* moving `#add_flag` to `Command` and renaming it `#add_option`
* adding `#add_env` to `Command` and `#add_option`, so one can add multiple environment variables
* adding `#add_switch` to Command so one does not have to use the `:is_boolean` parameter for `#add_flag`
* adding some sort of env_var type so one does not have to use the `:required` parameter for `#add_flag`
* the above will allow for multiple commands in a task with independent option, switch, and environment variable tracking

Rototiller has 4 main _types_ of arguments that can be passed to a command in a task. `RototillerTasks` can accept multiple commands.  Each of these argument types has a similar API that looks similar to `add_command()`.

<a name="use"></a>
## Use
It's just like normal Rake. We just added a bunch of task methods and messaging!
(with the below example Rakefile):

    $) rake -T
    rake parent_task  # some parent task
    rake test         # test all the things

    $) rake -D
    rake parent_task
        task dependencies work. this one also uses an environment variable
    rake test
        override command-name with environment variable


### Examples
    require 'rototiller'

    desc "task dependencies work. this one also uses an environment variable"
    rototiller_task :parent_task do |task|
      # most method initializers take either a hash, or block syntax (see next task)
      task.add_env({:name     => 'RANDOM_VAR', :default => 'default value'})
      task.add_command({:name => "echo 'i am testing everything with $RANDOM_VAR = #{ENV['RANDOM_VAR']}'"})
    end
produces:

    $) rake parent_task RANDOM_VAR=redrum
    INFO: The environment variable: 'RANDOM_VAR' was found with value: 'redrum':
    i am testing everything with $RANDOM_VAR = redrum
&nbsp;

    desc "override command-name with environment variable"
    rototiller_task :test => :parent_task do |task|
      # block syntax here. We give up some lines for more readability
      task.add_command do |cmd|
        cmd.name         = 'test'
        cmd.override_env = 'ECHO_EXECUTABLE'
      end
      task.add_command({:name => "echo $NONESUCH"})
    end
produces:

    # added environment variable defaults are set, implicitly, if not found
    #   this way, their value can be used in the task
    $) rake test
    INFO: The environment variable: 'RANDOM_VAR' was found with value: 'default value':
    i am testing everything with $RANDOM_VAR = default value
    The CLI flag -f will be used with value Rakefile.

    $) rake test ECHO_EXECUTABLE='ls' --verbose
    INFO: The environment variable: 'RANDOM_VAR' was found with value: 'default value':
    echo 'i am testing everything with $RANDOM_VAR = default value'
    i am testing everything with $RANDOM_VAR = default value
    The CLI flag -f will be used with value Rakefile.

    ls -f Rakefile
    Rakefile
&nbsp;

    desc "override command argument values with environment variables"
    rototiller_task :test_arg_env do |task|
      task.add_command do |cmd|
        cmd.name                  = 'ls'
        cmd.argument              = 'Rakefile' # FIXME: this will change to `#add_arg`
        cmd.argument_override_env = 'FILENAME'
      end
    end
produces:

    $) rake test_arg_env
    The CLI flag -f will be used with value Rakefile.
    $) echo $?
    0

    $) rake test_arg_env --verbose
    The CLI flag -f will be used with value Rakefile.

    test -f Rakefile

    $) rake test_arg_env --verbose FLAG_VALUE='README.md'
    The CLI flag -f will be used with value README.md.

    test -f README.md

    $) rake test_arg_env --verbose FLAG_VALUE='nonesuch'
    The CLI flag -f will be used with value README.md.

    test -f README.md
    test -f nonesuch failed

    $) rake test_arg_env
    Rakefile

    $) rake test_arg_env FILENAME=README.md
    README.md

## Issues

* none. it's perfect
* [Jira: Rototiller](https://tickets.puppetlabs.com/issues/?jql=project%20%3D%20QA)

## More Documentation

Rototiller is documented using yard
to view yard docs, including internal Classes and Modules:

First build a local copy of the gem

    $) bundle exec rake build

Next start the yard server

    $) bundle exec yard server

Finally navigate to http://0.0.0.0:8808/ to view the documentation

## Maintainers
* [Zach Reichert](zach.reichert@puppetlabs.com), github:[zreichert](https://github.com/zreichert), jira:zach.reichert
* [Eric Thompson](erict@puppetlabs.com), github:[er0ck](https://github.com/er0ck), jira:erict
* [QA](qa-team@puppetlabs.com)


## abandon hope, all ye who enter here
### All permutations of v2 API (remove and refactor into useful doc sections below upon testing, merge-up to stable)

* all things that can take multiples should use add\_ as precursor to method name
* all things that only take one should use set\_ as precursor to method name?
    require 'rototiller'

    ## all task methods
    rototiller_task :name do |t|
      t.add_command # t.add_cmd? me no likey
      t.add_env
    end
    rototiller_task do |t|
      t.set_name = 'string_name' # should this be validated??  e.g.: spaces, etc
      t.add_command
      t.add_env
    end


    ## all task's add_env invocations with just name
    t.add_env('env_name') #required, default messaging
    t.add_env :env_name
    t.add_env 'env_name' # implicitly allowed by ruby
    t.add_env do |e|
      e.name
    end

    ## all task's add_env invocations with name, message
    #t.add_env('env_name')  # impossible
    t.add_env :env_name do |e|
    t.add_env 'env_name' do |e|  # should we do this too?
      e.set_message
    end
    t.add_env do |e|
      e.name
      e.message
    end

    ## all task's add_env invocations with name, value
    #t.add_env('env_name')  # impossible
    t.add_env :env_name do |e|
    t.add_env 'env_name' do |e|  # should we do this too?
      e.default/value  # does value imply the env will be set by rototiller?  does default NOT?
    end
    t.add_env do |e|
      e.name
      e.default/value
    end

    ## all task's add_env invocations with name, value, message
    #t.add_env('env_name')  # impossible
    t.add_env :env_name do |e|
      e.default/value  # does value imply the env will be set by rototiller?  does default NOT?
      e.message
    end
    t.add_env do |e|
      e.name
      e.default/value
      e.message
    end


    ## all task's add_command invocations with only name
    # default messaging, no env override?
    t.add_command('echo --blah my name is ray')
    t.add_command :echo
    t.add_command 'echo'
    t.add_command do |c|
      c.name = 'echo'
    end

    ## all task's add_command invocations with name (string), message
    #t.add_command('echo --blah my name is ray', 'message') # ArgumentError
    t.add_command :echo
    t.add_command 'echo' do |c|
      c.name = 'echo' # # nomethod error?
      c.message = 'why we echo'
    end
    t.add_command do |c|
      c.name = 'echo'
      c.message = 'blah'
    end

    ## all task's add_command invocations with name (block) (could be same for message?)
    #t.add_command('echo --blah my name is ray', 'message') # ArgumentError
    #t.add_command :echo
    #t.add_command 'echo' do |c|
    #  c.message = 'blah'
    #end
    t.add_command do |c|
      c.name 'echo' do |n|
        n.add_env
      end
      c.add_arg 'some_arg' do |a|
        a.add_env
        a.message
      end
      c.add_option '--option_name' do |o|
        o.add_arg 'switch_arg' do |a|
          a.add_env 'opion-arg_env' do |e|
            e.set_name
            e.set_message
            e.set_value
          end
        end
        o.add_env 'option-name_env' do |e|
          e.set_name
          e.set_message
          e.set_value
        end
        o.message
      end
      c.add_switch '--some_switch' do |s|
        s.add_env 'env_name' do |e|
          e.set_name
          e.set_message
          e.set_value
        end
        s.message
      end
    end

    #should we be able to add an env for any given message?  i don't see a use case, we should probably just save users from themselves here.
