#!/usr/bin/env bash
# Ativa os git hooks versionados deste repo. Idempotente — rode uma vez após clonar.
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
git -C "$ROOT" config core.hooksPath .githooks
echo "setup-hooks: core.hooksPath = .githooks (hooks ativados)"
