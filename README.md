RFacter
=======

RFacter is a (highly) experimental fork of [Facter 2.x][2.x] that executes facts
defined in Ruby against remote systems over transports such as SSH and WinRM.

  [2.x]: https://github.com/puppetlabs/facter/tree/2.x


Running RFacter
--------------

Run the `rfacter` binary on the command and pass it a list of nodes to inspect:

    rfacter -n localhost -n some.remote.host \
      -n winrm://Administrator:password@some.windows.box

Special characters in passwords should be [percent-encoded][password-encoding].
I.e. `V@grant!` would become `V%40grant%21`.

  [password-encoding]: https://en.wikipedia.org/wiki/Percent-encoding


Adding your own facts
---------------------

Currently, custom facts can only be added by setting the `RFACTERLIB`
environment variable to a directories containing Ruby files:

    export RFACTERLIB=${HOME}/some_facts:/var/lib/rfacter/my_facts

The directories should contain Ruby files with names matching the fact being
defined. For example, the RFacter loader will expect `my_fact` to be defined in
a file named `my_fact.rb` somewhere on the `RFACTERLIB` path. Custom facts can
make use of the Facter 3 Ruby DSL:

  https://github.com/puppetlabs/facter/blob/master/Extensibility.md#custom-facts-compatibility

Additional methods of configuring the loader will be added in a future release.
