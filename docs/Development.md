# Development

In order to develop highway locally (without pushing anything to GitHub) you have to adjust a few environment variables:

- Set `HIGHWAY_DEV_HOME` to the directory which contains the highway working copy.
- Set `HIGHWAY_REPOSITORY` (URI to the highway git repository used by the highway command line tool) and `HIGHWAY_BRANCH` (the branch of used by the highway command line tool when creating/updating highway projects).

Once you have set `HIGHWAY_DEV_HOME` you can set the other two environment variables by executing:

```
$ source $HIGHWAY_DEV_HOME/scripts/setEnv.sh develop
```
Replace `develop` with the branch you want to use.

## Creating an Alias
In order to easily use the most recent local build of highway set up an alias. First determine the location of your local highway executable:

```
$ swift build --package-path $HIGHWAY_DEV_HOME --show-bin-path
```

On my Mac the command creates the following output:

```
/Users/chris/highway_tool/.build/x86_64-apple-macosx10.10/debug
```

Append `highway` to the output and use the resulting absolute path to create the alias (for example in your `~/.bash_profile` config file):

```
alias hwdev='~/highway_tool/.build/x86_64-apple-macosx10.10/debug/highway'
alias hwrel='~/highway_tool/.build/x86_64-apple-macosx10.10/release/highway'
```

You can now use `hwdev` (to use the latest debug build) and `hwrel` (to use the latest release build).
