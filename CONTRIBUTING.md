# How To Contribute To Rototiller

## Getting Started

* Make sure you have a [GitHub account](https://github.com/signup/free).
* Fork the [Rototiller repository on GitHub](https://github.com/puppetlabs/rototiller).

## Making Changes

* (!) Rototiller uses [`gem_of`](https://github.com/puppetlabs/gem_of) for the gemfile and rake tasks.
 Initialize and update the `gem_of` submodule:
    ```
    git submodule init
    git submodule update
    ```

* Create a topic branch from where you want to base your work.
  * Typically you'd stem from the `master` or `stable` branch in the case of rototiller.
    * `master` holds the versions that contain breaking changes and is reserved for _major_ versions. e..g.: `2.0.0`
    * `stable` holds the version that contain bug fixes and non-breaking features on top of the most previous major _X_ release. e.g.: `2.1.3`
  * To quickly create a topic branch based on master use `git checkout -b my_contribution master`. Do not work directly on the `master` branch.
* Make commits of logical _working_ and _functional_ units.
* Check for unnecessary whitespace with `git diff --check` before committing.
* Make sure your commit messages are in the proper format.

        (BKR-1234) Make the example in CONTRIBUTING imperative and concrete

        Without this patch applied the example commit message in the CONTRIBUTING
        document is not a concrete example. This is a problem because the
        contributor is left to imagine what the commit message should look like
        based on a description rather than an example. This patch fixes the
        problem by making the example concrete and imperative.

        The first line is a real life imperative statement with a ticket number
        from our issue tracker. The body describes the behavior without the patch,
        why this is a problem, and how the patch fixes the problem when applied.

* Make sure you have added [RSpec](http://rspec.info/) tests that exercise your new code. These test should be located in the appropriate `rototiller/spec/` subdirectory. The addition of new methods/classes or the addition of code paths to existing methods/classes requires additional RSpec coverage.
  * One should **NOT USE** the deprecated `should`/`stub` methods - **USE** `expect`/`allow`. Use of deprecated RSpec methods will result in your patch being rejected.  See a nice blog post from 2013 on [RSpec's new message expectation syntax](http://teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/).
* Run the spec unit tests to assure nothing else was accidentally broken, using `rake test`.
  * **Bonus**: if possible ensure that `[bundle exec] rake test` runs without failures for additional Ruby versions (1.9, 2.0, etc). Rototiller supports Ruby 1.9+, and breakage of support for other rubies will cause a patch to be rejected.
* Make sure that if you have added new functionality of sufficiently high risk, and it can not be covered adequately via unit tests (mocking, requires disk, other classes, etc), you also include acceptance tests in your PR.
* Make sure that you have added documentation using [Yard](http://yardoc.org/), new methods/classes without appropriate documentation will be rejected.
  * Run the yardoc tool to ensure that your yard documentation is properly formatted and complete:
      ```
      [bundle exec] rake docs:gen
      ```
* Yard docs are great for other developers, but often are difficult to read for users. If your change impacts user-facing functionality, please include changes to the human-readable markdown docs starting at README.md
* During the time that you are working on your patch the master Rototiller branch may have changed - you'll want to [rebase](http://git-scm.com/book/en/Git-Branching-Rebasing) before you submit your PR with `git rebase master`. A successful rebase ensures that your patch will cleanly merge into Rototiller.
* Submitted patches will be smoke tested through a series of acceptance level tests that ensures basic Rototiller functionality - the results of these tests will be evaluated by a Rototiller team member. Failures associated with the submitted patch will result in the patch being rejected.

## Testing

* (!) Ensure you have initialized and updated the `gem_of` submodule:
    ```
    git submodule init
    git submodule update
    ```
* `bundle install`
* Run the unit tests:
  * This runs rspec on the local machine.
  * Do not write tests that could mess with the local machine.
  * `bundle exec rake test:unit`
* Run the acceptance tests:
  * Some of these could theoretically do weird stuff to the local system so we run these in a container.
  * A running docker server is required:
    ```
    docker login pcr-internal.puppet.net
    docker pull pcr-internal.puppet.net/slv/rototiller:latest
    ```

  * We'll  mirror the image to docker soon, probably, for your local testing, outside of Puppet.
  * `bundle exec rake test:acceptance`

  These tests all run in CI. The unit tests are also run in the container to save time in the repeated bundle installs and rvm setup steps. You are welcome to use the container as well if you want to avoid the bundle install. Just `gem install rototiller` to make our own Rakefile _go_ and you can `rake test:unit` all day.

## Submitting Changes

* Sign the [Contributor License Agreement](http://links.puppet.com/cla).
* Push your changes to a topic branch in _your_ fork of the repository.
* Submit a pull request to [Rototiller](https://github.com/puppetlabs/rototiller).
* PRs are reviewed as time permits.

# Additional Resources

* [Rototiller's Yard Docs](http://www.rubydoc.info/github/puppetlabs/rototiller) (API/internal Architecture docs)
* [Rototiller's Architecture](docs/arch_graph.png)
* [More information on contributing](http://links.puppet.com/contribute-to-puppet)
* [Contributor License Agreement](http://links.puppet.com/cla)
* [General GitHub documentation](http://help.github.com/)
* [GitHub pull request documentation](http://help.github.com/send-pull-requests/)
* Questions?  Comments?  Contact the Rototiller team at qa-team@puppet.com.
  * The keyword `rototiller` is monitored and we'll get back to you as quick as we can.
* Rototiller's Architecture: [Rototiller's Architecture](docs/arch_graph.png)

## Submitting Changes

* Sign the [Contributor License Agreement](http://links.puppet.com/cla).
* Push your changes to a topic branch in _your_ fork of the repository.
* Submit a pull request to [Rototiller](https://github.com/puppetlabs/rototiller)
* PRs are reviewed as time permits.
