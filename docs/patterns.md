# Patterns and Design Principles

## Tooling
- prefer using `fd` in private repos, `find` for public repos
- assume GNU coreutils and prefer those to local OS versions (e.g. macOS)

## Project Management
- use GitHub Issues of the main repo for project management
- use `docs/` folder for project documentation

## Documentation
- use the README.org file to provide a 'Quickstart' explaining the project and how to get started to a new developer/user, with links to more detailed documentation in `docs/`
- there should not be a README.md if there is a README.org
- when referencing local paths, instead of absolute paths use relative to `$HOME` using `~` notation, e.g. `~/code/www/omni/` instead of `/Users/tigger/code/www/omni/`

## Coding
- For shell scripts, for private projects use bash 5 and include a version check.
- For public projects maintain bash v3.2 compatibility.
- Use portable shebang `#!/usr/bin/env bash`
- prefer bash/shell builtins to external commands where possible
- avoid superfluous subshells, use `read` and `mapfile` in shell scripts instead where possible

## Testing
- For shell testing use `bats-core` framework
- For Hugo sites, fail loudly with `hugo --environment production --minify --panicOnWarning` - this should catch any linting errors
- use `htmltest` to validate generated HTML files
- create a makefile target `make test` to run all tests

## Deployment
- Build and test locally on the master branch
- Once tests pass, commit and push to remote
- If GitHub Actions are triggered, make sure they pass and nothing is broken

## Security
- Never ever store or hardcode secrets in code or in the repository
- Never store Personally Identifiable Information (PII) in the repository, with the exception of the name of the developer/owner/maintainer of the project and references to usernames of individuals interacting in the GitHub Issues.
