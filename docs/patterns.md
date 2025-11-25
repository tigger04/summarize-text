# Patterns and Design Principles

## Tooling
- prefer `fd` to `find` command
- assume GNU coreutils and prefer those to local OS versions (e.g. macOS)

## Project Management
- use GitHub Issues of the main repo `tigger04/www-omni` for project management
- use `docs/` folder in the main repo for project documentation

## Documentation
- use the README.org file to provide a 'Quickstart' explaining the project and how to get started to a new developer/user, with links to more detailed documentation in `docs/`
- there should not be a README.md if there is a README.org
- when referencing local paths, instead of absolute paths use relative to `$HOME` using `~` notation, e.g. `~/code/www/omni/` instead of `/Users/tigger/code/www/omni/`

## Coding
- for shell scripts use bash 5. On macOS this may be installed in `/opt/homebrew/bin/bash`, assume that is in the path and use appropriate shebang `#!/usr/bin/env bash` but include a bash version check
- prefer bash/shell builtins to external commands where possible (esp for regular expressions etc)
- avoid superfluous subshells, use `read` and `mapfile` in shell scripts instead where possible

## Testing
- For shell testing use `bats-core` framework
- For Hugos sites, fail loudly with `hugo --environment production --minify --panicOnWarning` - this should catch any linting errors
- use `htmltest` to validate generated HTML files
- create a makefile target `make test` to run all tests

## Deployment
- Build and test locally on the main branch
- Once tests pass, merge to main branch
- If GitHub Actions are triggered, make sure they pass and nothing is broken
