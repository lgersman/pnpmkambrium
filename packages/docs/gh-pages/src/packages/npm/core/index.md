# @pnpmkambrium/core

<!-- toc -->

{{#include ./../../../../../../../packages/npm/core/README.md}}

# FAQ

- Some files are ignored by GIT version control but I cannot find a `.gitignore` file. Why is it ignored ?

`@pnpmkambrium/core` configures a default set of GIT ignored resources (like `build`/`dist` directories) in `.git/info/exclude`.

`.git/info/exclude` is a standard GIT file intended for local usage only by GIT. It has same semantics and meaning as `.gitignore` but a lower priority (`.gitignore` rules override `.git/info/exclude` rules).

Package `@pnpmkambrium/core` will link `.git/info/exclude` to an built-in git ignore exclude file declaring all pnpmkambrium intermediate files.

If you worry about a untracked file you can ask GIT what's the reason :

```
# ask GIT why file build-info is not tracked by GIT
$> git check-ignore -v build-info
# GIT tells you what file/line-in-file was the reason
$> .git/info/exclude:13:build-info build-info
```

As mentioned `.git/info/exclude` is the file containing the pnpm kambrium git ignore rules.
It is linked to a file provided by package `@pnpmkambrium/core` :

```
# ask the systen where .git/info/exclude is linked to
$> ls -la .git/info/exclude
# thats the git ignore file provided by pnpmkambrium
$> lrwxrwxrwx 1 user user 50 Mar  2 15:12 .git/info/exclude -> node_modules/@pnpmkambrium/core/presets/default/.gitignore
```

If you want to override a setting of the default ignore list provided by `@pnpmkambrium/core` you can do this by providing a `.gitignore` file and mention the file you want to track with git :

```
# situation: .env files are listed in the pnpmkambrium git ignore list
# (=> .env files may contain secrets/tokens/passwords, thats why pnpmkambrium configured git to ignore .env files from being tracked)
$> echo "!/.env" > .gitignore
# now we have a .gitignore file with a single line telling git to NO MORE(!) ignore .env files
```
