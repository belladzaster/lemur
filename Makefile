NPM_ROOT = ./node_modules
STATIC_DIR = src/lemur/static/app

develop: update-submodules setup-git
	@echo "--> Installing dependencies"
	npm install
	pip install "setuptools>=0.9.8"
	# order matters here, base package must install first
	pip install -e .
	pip install "file://`pwd`#egg=lemur[dev]"
	pip install "file://`pwd`#egg=lemur[tests]"
	node_modules/.bin/gulp build
	node_modules/.bin/gulp package
	@echo ""

dev-docs:
	pip install -r docs/requirements.txt

reset-db:
	@echo "--> Dropping existing 'lemur' database"
	dropdb lemur || true
	@echo "--> Creating 'lemur' database"
	createdb -E utf-8 lemur
	@echo "--> Applying migrations"
	lemur db upgrade

setup-git:
	@echo "--> Installing git hooks"
	git config branch.autosetuprebase always
	cd .git/hooks && ln -sf ../../hooks/* ./
	@echo ""

clean:
	@echo "--> Cleaning static cache"
	${NPM_ROOT}/.bin/gulp clean
	@echo "--> Cleaning pyc files"
	find . -name "*.pyc" -delete
	@echo ""

test: develop lint test-python

testloop: develop
	pip install pytest-xdist
	py.test tests -f

test-cli:
	@echo "--> Testing CLI"
	rm -rf test_cli
	mkdir test_cli
	cd test_cli && lemur create_config -c ./test.conf > /dev/null
	cd test_cli && lemur -c ./test.conf db upgrade > /dev/null
	cd test_cli && lemur -c ./test.conf help 2>&1 | grep start > /dev/null
	rm -r test_cli
	@echo ""

test-js:
	@echo "--> Running JavaScript tests"
	npm test
	@echo ""

test-python:
	@echo "--> Running Python tests"
	py.test lemur/tests || exit 1
	@echo ""

lint: lint-python lint-js

lint-python:
	@echo "--> Linting Python files"
	PYFLAKES_NODOCTEST=1 flake8 lemur
	@echo ""

lint-js:
	@echo "--> Linting JavaScript files"
	npm run lint
	@echo ""

coverage: develop
	coverage run --source=lemur -m py.test
	coverage html

publish:
	python setup.py sdist bdist_wheel upload

.PHONY: develop dev-postgres dev-docs setup-git build clean update-submodules test testloop test-cli test-js test-python lint lint-python lint-js coverage publish