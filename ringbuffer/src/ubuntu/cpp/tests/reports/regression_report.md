# Regression Verification Report - Ubuntu 24.04 LTS
**Date:** 2026-08-11

## Test Results
| Test ID | Description | Result | Note |
| :--- | :--- | :--- | :--- |
| T001 | Exact match with input | PASS | exit=0 (expected 0) |
| T002 | Stress test (1 slot, 1 byte) | PASS | exit=0 (expected 0) |
| T003 | All chars uppercase | PASS | exit=0 (expected 0) |
| T004 | Input < 1 slot (fast EOF) | PASS | exit=0 (expected 0) |
| T005 | Pipeline stop (Fatal Error) | PASS | exit=1 (expected 1) |
| T006 | Pipeline continues (Non-fatal) | PASS | exit=0 (expected 0) |
| T007 | Bit-inverted output | PASS | exit=0 (expected 0) |
