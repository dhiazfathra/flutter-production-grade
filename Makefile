FLUTTER := $(shell command -v fvm >/dev/null 2>&1 && echo "fvm flutter" || echo flutter)
DART := $(shell command -v fvm >/dev/null 2>&1 && echo "fvm dart" || echo dart)

.PHONY: get gen watch l10n run-dev test cov lint goldens integration schema doctor

get:
	$(FLUTTER) pub get

gen:
	$(DART) run build_runner build --delete-conflicting-outputs

watch:
	$(DART) run build_runner watch --delete-conflicting-outputs

l10n:
	$(FLUTTER) gen-l10n

run-dev:
	$(FLUTTER) run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json

test:
	$(FLUTTER) test --dart-define-from-file=config/example.json

cov:
	$(FLUTTER) test --coverage --dart-define-from-file=config/example.json && ./tool/coverage.sh

goldens:
	$(FLUTTER) test --update-goldens --tags golden

lint:
	$(DART) format --set-exit-if-changed lib test
	$(FLUTTER) analyze --fatal-infos

integration:
	$(FLUTTER) drive --driver=test_driver/integration_test.dart \
		--target=integration_test/app_test.dart -d chrome \
		--dart-define-from-file=config/example.json

doctor:
	./tool/doctor.sh
