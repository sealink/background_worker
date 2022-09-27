# Change Log

All notable changes to this project will be documented in this file.  
This project adheres to [Semantic Versioning](http://semver.org/).  
This changelog adheres to [Keep a CHANGELOG](http://keepachangelog.com/).

## Unreleased

- [PLAT-749] Rename `uid` as `job_id` and make it a base property of job.
- [PLAT-759] Add callbacks
- [PLAT-761] Extract logging concern
- [PLAT-760] Extract status concern

## 0.8.1

- Fix version

## 0.8.0

- [PLAT-747] Remove the ability to pass through `method_name`

## 0.7.0

- [PLAT-670] Add queue_as method

## 0.6.0

- [PLAT-664] Align interface to ActiveJob

## 0.5.0

- [PLAT-183] Ruby 3.1, Rails 7.0 and push coverage with github action

## 0.4.0

- [TT-8623] Update to build with github actions / ruby 3.0 / rails 6.1

## 0.3.0

- [TT-6292] Support Rails 5.2 built-in redis cache, remove legacy supports

## 0.2.1

### Fixed

- [RU-123] Worker disconnecting within transactions in rails 4+

## 0.2.0

### Added

- [RU-79] Release connections after execution for Rails 4

## 0.1.0

### Added

- [TT-1392] Changelog file
- [TT-2141] Only verify connections for Rails 3
