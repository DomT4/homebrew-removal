Homebrew-removal
========

Homebrew-removal is a tiny, single-purpose Homebrew tap that adds an internal Homebrew command enabling you to destroy your Homebrew installation.

There are various scripts out there that do this without tapping Homebrew’s useful internal API and self-awareness, so I tweaked a pre-existing useful [Gist](https://gist.github.com/SteveBenner/11254428) to use more internal Homebrew capabilities and not lean on shell so much.

Usage
===

To run the script, you’d just do `brew selfdestruct`. It will ask you for confirmation that you’d like to remove Homebrew prior to doing anything. There’s also a `brew selfdestruct --dry-run` command if you’d like to see what it does.

How do I tap this repository?
===
Just `brew tap domt4/removal`.