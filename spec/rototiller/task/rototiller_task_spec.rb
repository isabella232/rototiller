require "spec_helper"
require "stringio"

module Rototiller
  # rubocop:disable Metrics/ModuleLength
  module Task
    # rubocop:disable Metrics/BlockLength
    describe RototillerTask do
      %i[new define_task].each do |init_method|
        let(:task) { described_class.send(init_method) }

        before(:each) do
          # stub out all the PRY env use, or the mocks for ENV below will break pry
          # pryrc = ENV['PRYRC']
          # disable_pry = ENV['DISABLE_PRY']
          # home = ENV['HOME']
          # ansicon = ENV['ANSICON']
          # term = ENV['TERM']
          # pager = ENV['PAGER']
          # rake_columns = ENV['RAKE_COLUMNS']
          # lines = ENV['LINES']
          # rows = ENV['ROWS']
          # columns = ENV['COLUMNS']
          # bundle_major_deprecations = ENV['BUNDLE_MAJOR_DEPRECATIONS']
          # allow(ENV).to receive(:[]).with('PRYRC').and_return(pryrc)
          # allow(ENV).to receive(:[]).with('DISABLE_PRY').and_return(disable_pry)
          # allow(ENV).to receive(:[]).with('HOME').and_return(home)
          # allow(ENV).to receive(:[]).with('ANSICON').and_return(ansicon)
          # allow(ENV).to receive(:[]).with('TERM').and_return(term)
          # allow(ENV).to receive(:[]).with('PAGER').and_return(pager)
          # allow(ENV).to receive(:[]).with('RAKE_COLUMNS').and_return(rake_columns)
          # allow(ENV).to receive(:[]).with('LINES').and_return(lines)
          # allow(ENV).to receive(:[]).with('ROWS').and_return(rows)
          # allow(ENV).to receive(:[]).with('COLUMNS').and_return(columns)
          # allow(ENV).to receive(:[]).with('BUNDLE_MAJOR_DEPRECATIONS')
          #           .and_return(bundle_major_deprecations)
        end
        context "new: no args, no block" do
          it "inits members with '#{init_method}' method" do
            expect(task.name).to be nil
            expect(task.fail_on_error).to eq true
          end

          def described_define
            task.__send__(:define, nil)
          end
          it "registers the task" do
            expect(described_define).to be_an_instance_of(Rake::Task)
          end
        end

        # FIXME: damnit, where is this extra newline coming from?
        #   i'm pretty sure it's the way we're printing empty messages from Command or EnvVar
        # it "doesn't have spurious newlines" do
        #   expect{ described_run_task }.not_to output(anything).to_stdout
        # end

        context "with a name passed to the '#{init_method}' constructor" do
          task_named = described_class.send(init_method, :task_name)
          # using the let, spews the system call on stdout??
          # let(:task_named) { described_class.send(init_method,:task_name) }

          it "creates a default description with '#{init_method}'" do
            expect(task_named).to receive(:run_task) { true } unless init_method == :define_task
            # FIXME: WHY does define_task not appear to work here (works in acceptance)
            unless init_method == :define_task
              expect(Rake.application.invoke_task("task_name"))
                .to be_an(Array)
            end
            # this will fail if previous tests don't adequately clear the desc stack
            # http://apidock.com/ruby/v1_9_3_392/Rake/TaskManager/get_description
            expect(Rake.application.last_description).to eq "RototillerTask: A Task with " \
              "optional environment-variable and command-flag tracking"
          end
          # TODO: override comment
          it "doesn't say last_comment is deprecated '#{init_method}'" do
            expect { described_run_task }.not_to output(/\[DEPRECATION\] `last_comment`/).to_stdout
          end

          it "correctly sets the name" do
            expect(task_named.name).to eq :task_name
          end
        end

        context "with args passed to the '#{init_method}' rake task" do
          it "correctly passes along task arguments" do
            task_w_args = described_class.send(init_method, :rake_task_args, :files) do |_t, args|
              expect(args[:files]).to eq "first"
            end

            expect(task_w_args).to receive(:run_task) { true } unless init_method == :define_task
            unless init_method == :define_task
              expect(Rake.application.invoke_task("rake_task_args[first]"))
                .to be_an(Array)
            end
          end
        end

        def described_run_task
          task.__send__(:run_task)
        end

        def silence_output(&block)
          expect(&block).to output(anything).to_stdout.and output(anything).to_stderr
        end

        # can't use the task.add_env stuff below with define_task
        if init_method == :new
          it "correctly indents messages" do
            task.add_env(name: "TASKENVVAR", default: "somevalue", message: "task env message")
            c = task.add_command(name: "echo something", message: "command message")
            c.add_env(name: "SOMEENVVAR", message: "command env message")
            c.add_argument do |a|
              a.name = "--myargument"
              a.add_env(name: "ARGENV", message: "args env message")
            end
            c.add_option do |o|
              o.name = "--myoption"
              o.add_env(name: "OPTENV", message: "option env message")
              o.add_argument do |a|
                a.name = "optionarg"
                a.add_env(name: "OPTARGENV", message: "options args env message")
              end
            end
            # FIXME: wth is this extra newline? see other test above as well
            # rubocop:disable Layout/IndentHeredoc
            #   a cop with a required 3rd party dep? F the F off
            expected_output = <<-HERE
\e[32m[I] \e[0m'TASKENVVAR': using default: 'somevalue'; 'task env message'
\e[32mrunning: \e[0mecho something --myoption optionarg --myargument
  \e[32mwith message: \e[0mcommand message
  \e[32m[I] \e[0m'SOMEENVVAR': using default: 'echo something'; 'command env message'
  \e[32m[I] \e[0m'OPTENV': using default: '--myoption'; 'option env message'
  \e[32m[I] \e[0m'OPTARGENV': using default: 'optionarg'; 'options args env message'

  \e[32m[I] \e[0m'ARGENV': using default: '--myargument'; 'args env message'
something --myoption optionarg --myargument
            HERE
            expect { described_run_task }.to output(expected_output).to_stdout
          end
        end

        context "when `command message` is configured" do
          before do
            allow(task).to receive(:exit)
          end

          it "prints it if the command run failed" do
            task.add_command(name: "exit 1", message: "Bad news")
            expect { described_run_task }.to output(/Bad news/).to_stderr
          end

          it "prints it if the command run succeeded" do
            task.add_command(name: "echo")
            expect { described_run_task }.not_to output(/Bad/).to_stderr
            expect { described_run_task }.not_to output(/Bad/).to_stdout
          end
        end

        context "with custom exit status" do
          it "returns the correct status on exit", :slow do
            expect(task).to receive(:exit).with(2)
            task.add_command(name: 'ruby -e "exit(2);" ;#')
            described_run_task
          end
        end

        context "verbose and fail_on_error" do
          def described_verbose(verbose)
            task.__send__(:make_verbose, verbose)
          end
          it "prints command failed" do
            if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.0.0")
              expect(task).to receive(:exit).with(127)
            else
              expect(task).to receive(:exit).with(2)
            end

            # FIXME: despite the silence_output some of these are spewing
            #  this is because we set command to "echo empty RototillerTask.
            #  You should define a command, send a block, or EnvVar to track."
            #  so any of these that run system spews that to the output.
            #  We should probably not set as the default command.  it's a bit verbose and pedantic.
            #  it doesn't check if there are any envs or other tasks,
            #  and there are good reasons to not have a command, in some cases
            silence_output do
              task.add_command(name: "exit 2")
              described_verbose(true)
              expect { described_run_task }.to output(/failed/).to_stderr
              described_verbose(false)
            end
          end
          it 'doesn\'t print if fail_on_error is false' do
            expect(task).to_not receive(:exit)
            task.fail_on_error = false
            task.add_command(name: "exit 2")
            # some versions have two newlines after exit?
            # sigh
            if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.0.0")
              expect { described_run_task }
                .to output(/No such file or directory - exit 2/).to_stderr
            else
              expect { described_run_task }.to output("\n").to_stderr
            end
          end
        end
        # also, the task takes care of printing the command, now
        it 'doesn\'t print if fail_on_error is false' do
          expect(task).to_not receive(:exit)
          task.fail_on_error = false
          task.add_command(name: "exit 2")
          # some versions have two newlines after exit?
          # sigh
          if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.0.0")
            expect { described_run_task }.to output(/No such file or directory - exit 2/).to_stderr
          else
            expect { described_run_task }.to output("\n").to_stderr
          end
        end

        # confined to 'new' init method, dirty test env (rspec--)
        # rubocop:disable Style/Next
        #   using next here would get messy if someone wants to easily add tests to the end of this
        #   block
        if init_method == :new
          context "name default relationship" do
            it "uses the name when there is no default" do
              validation = "I_AM_THE_NAME"
              command = { name: "echo #{validation}", add_env: { name: "FOOBAR" } }
              task.add_command(command)
              expect { described_run_task }.to output(/#{validation}/).to_stdout
            end

            it "prefers the default over the name" do
              validation = "I_AM_THE_DEFAULT"
              command = { name: "echo I_AM_THE_NAME",
                          add_env: { name: "FOOBAR", default: "echo #{validation}" } }
              task.add_command(command)
              expect { described_run_task }.to output(/#{validation}/).to_stdout
            end
          end
        end
      end

      context "#add_env" do
        let(:env_name) { unique_env }
        let(:env_desc) { "used in some task for some purpose" }
        # TODO: add expect to raise with other case, if possible
        it "raises argument error for too many env string args" do
          expect { task.add_env("-t", "-t description", "tvalue2", "someother") }
            .to raise_error(ArgumentError)
        end
        it "add_env can take 4 EnvVar args" do
          task.add_env({ name: env_name, message: env_desc }, { name: "VAR2", message: env_desc },
                       { name: "VAR3", message: env_desc }, name: env_name, message: env_desc)
          expect(task).to receive(:exit)
          expect { described_run_task }
            .to output(/\[E\] required: .*#{env_name}.*#{env_desc}.*VAR2.*VAR3.*/m)
            .to_stdout
        end
      end
    end
  end
end
