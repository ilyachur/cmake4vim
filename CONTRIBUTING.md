# Contributing to cmake4vim

We love your input! We want to make contributing to this project as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

Do you feel like contributing code? Cool, together we can make this plugin better!

## Develop with Github

We use github to host code, to track issues and feature requests, as well as accept pull requests.

## All Code Changes Happen Through Pull Requests

We use [Github Flow](https://guides.github.com/introduction/flow/index.html) model, that means that each code changes requires pull request.
We actively welcome your pull requests:

1. Fork the repo and create your branch from `master`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Issue that pull request!

## Any contributions you make will be under the GNU GPL 3.0 Software License

In short, when you submit code changes, your submissions are understood to be under the same [GNU GPL 3.0 License](LICENSE) that covers the project.
Feel free to contact the maintainers if that's a concern.

## Report bugs using Github's [issues](https://github.com/ilyachur/cmake4vim/issues)

We use GitHub issues to track public bugs. Report a bug by [opening a new issue](https://github.com/ilyachur/cmake4vim/issues/new); it's that easy!

## Use a Consistent Coding Style

In the project is used the [Google Vimscript Code Style](https://google.github.io/styleguide/vimscriptguide.xml) with a few exceptions:
- use four spaces for indents (not two)
- restrict lines to 160 columns wide

Use [Vint](https://github.com/Vimjas/vint) to code style check.

Use the next command to run code style check:
```
vint <root-project-dir>
```

## Testing

The test suite is written using [Vader](https://github.com/junegunn/vader.vim). You can use next script to run all tests:
```
<root-project-dir>/test/local_run.sh
```
