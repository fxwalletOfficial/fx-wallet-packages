# Contributing to fx-wallet-packages

Thank you for your interest in contributing to fx-wallet-packages! This document provides guidelines for contributing to this project.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Install dependencies:
   ```bash
   dart pub global activate melos
   melos bootstrap
   ```

## Development Workflow

1. Create a feature branch from `main`
2. Make your changes
3. Run tests and analysis:
   ```bash
   melos run test
   melos run analyze
   melos run format
   ```
4. Update CHANGELOG.md for the affected package(s)
5. Submit a pull request

## Code Style

- Follow Dart/Flutter conventions
- Use meaningful commit messages
- Add tests for new features
- Update documentation as needed

## Pull Request Guidelines

- Provide a clear description of changes
- Include tests if applicable
- Update relevant documentation
- Ensure all CI checks pass

## Issues

- Use the issue templates if available
- Provide clear reproduction steps
- Include relevant system information

## License

By contributing, you agree that your contributions will be licensed under the MIT License.