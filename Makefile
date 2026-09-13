FLUTTER := fvm flutter
DART := fvm dart

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
	$(FLUTTER) test --dart-define-from-file=config/dev.json

cov:
	$(FLUTTER) test --coverage --dart-define-from-file=config/dev.json && ./tool/coverage.sh

goldens:
	$(FLUTTER) test --update-goldens --tags golden

lint:
	$(DART) format --set-exit-if-changed lib test
	$(FLUTTER) analyze --fatal-infos

integration:
	$(FLUTTER) drive --driver=test_driver/integration_test.dart \
		--target=integration_test/app_test.dart -d chrome

doctor:
	./tool/doctor.sh
