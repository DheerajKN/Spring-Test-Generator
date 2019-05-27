# Changelog

All notable changes to this project will be documented in this file.

## [Releases]

## [1.0.7] - 2019-05-21

### Added

- --no-auth flag added that can be used in --initialData that creates initial snippets without OAuth2.

### Changed

- File information is neccessary and to be passed in first argument.
- Now user can create test java files from any json file present in any directory instead of tests.json on same level on the condition that syntax in the json file is in the required way.

## [1.0.4] - 2019-05-01

### Added

- Functions for code reusability
- CHANGELOG.md
- Added Badges

### Changed

- Fetching javaVariable or dbVariable can be done via functions
- RepoCode now is variablized for better control.
- Now Folder creation command will be based on flag.
- Removed import variable, now users have to add package of the main file in test directory.

## [1.0.0] - 2019-04-18

### Added

- Initial Commit
- Documentation of the project
- MIT License .md

### Changed

- Understanable Error Comments for better debugging.

### Removed

- Multiple Imports from single Parent are removed to include Common Parent Imports using .\*;
